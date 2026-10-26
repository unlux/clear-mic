import AVFoundation
import ClearMicCore
import ClearMicModel
import Foundation

struct AudioMetrics: Sendable {
    var inputLevel: Double = 0
    var outputLevel: Double = 0
    var processingMS: Double = 0
    var queueMS: Double = 0
    var underrunFrames: UInt64 = 0
}

final class AudioControls: @unchecked Sendable {
    private let lock = NSLock()
    private var strength = 1.0
    func set(_ value: Double) { lock.lock(); strength = value; lock.unlock() }
    func get() -> Double { lock.lock(); defer { lock.unlock() }; return strength }
}

@MainActor final class AudioPipeline {
    private var inputEngine: AVAudioEngine?
    private var outputEngine: AVAudioEngine?
    private var worker: Task<Void, Never>?
    private var notifications: [NSObjectProtocol] = []
    let controls = AudioControls()
    nonisolated static let hop = 960 // 20 ms; model uses a sliding 2 s context.

    func start(input: AudioDevice, output: AudioDevice, processor: ClearProcessor,
               update: @escaping @MainActor @Sendable (AudioMetrics) -> Void,
               failed: @escaping @MainActor @Sendable (String) -> Void) throws {
        guard input.id != output.id, !input.virtual, output.virtual, output.output else {
            throw MicError.message("Choose a physical microphone and a separate virtual output device.")
        }
        let capture = AVAudioEngine()
        let playback = AVAudioEngine()
        let inputNode = capture.inputNode
        try setDevice(inputNode.audioUnit, to: input.id)
        try setDevice(playback.outputNode.audioUnit, to: output.id)
        let native = inputNode.outputFormat(forBus: 0)
        guard native.sampleRate > 0, native.channelCount > 0, native.commonFormat == .pcmFormatFloat32, !native.isInterleaved,
              let sourceFormat = AVAudioFormat(standardFormatWithSampleRate: native.sampleRate, channels: 1),
              let targetFormat = AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: 1),
              let converter = AVAudioConverter(from: sourceFormat, to: targetFormat) else {
            throw MicError.message("This microphone's audio format is unsupported. Try the built-in microphone.")
        }
        converter.primeMethod = .none
        let incoming = AudioFIFO(capacity: Int(native.sampleRate))
        let outgoing = AudioFIFO(capacity: 48_000)
        let source = makeOutputSource(fifo: outgoing, format: targetFormat)
        playback.attach(source)
        playback.connect(source, to: playback.mainMixerNode, format: targetFormat)
        // Only channel one of the selected microphone is captured. The output
        // mixer maps our mono speech to the virtual device's channel layout.
        inputNode.installTap(onBus: 0, bufferSize: 256, format: native) { buffer, _ in
            if let channel = buffer.floatChannelData?[0] {
                _ = incoming.write(channel, count: Int(buffer.frameLength))
            }
        }
        inputEngine = capture
        outputEngine = playback
        do {
            playback.prepare()
            try playback.start()
            capture.prepare()
            try capture.start()
        } catch {
            stop()
            throw error
        }

        for engine in [capture, playback] {
            notifications.append(NotificationCenter.default.addObserver(forName: .AVAudioEngineConfigurationChange, object: engine, queue: .main) { _ in
                Task { @MainActor in failed("An audio device changed or disconnected. Refresh devices and start again.") }
            })
        }
        let controls = self.controls
        let rate = native.sampleRate
        worker = Task.detached(priority: .userInitiated) {
            let batch = 1_024
            guard let inputBuffer = AVAudioPCMBuffer(pcmFormat: sourceFormat, frameCapacity: AVAudioFrameCount(batch)),
                  let converted = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: AVAudioFrameCount(Double(batch) * 48_000 / rate) + 256) else {
                await failed("Could not allocate the microphone converter.")
                return
            }
            var pending = [Float]()
            pending.reserveCapacity(4_096)
            var lastUpdate = ContinuousClock.now
            var lastInput = ContinuousClock.now
            var outputStarted = false
            do {
                while !Task.isCancelled {
                    if incoming.dropped > 0 || Double(incoming.count) / rate > 0.25 || outgoing.count > 12_000 {
                        throw MicError.message("Audio processing fell behind. Stop other audio effects and try again.")
                    }
                    let read = incoming.read(inputBuffer.floatChannelData![0], count: min(batch, incoming.count))
                    if read > 0 {
                        lastInput = .now
                        inputBuffer.frameLength = AVAudioFrameCount(read)
                        var supplied = false
                        var conversionError: NSError?
                        let status = converter.convert(to: converted, error: &conversionError) { _, state in
                            if supplied { state.pointee = .noDataNow; return nil }
                            supplied = true
                            state.pointee = .haveData
                            return inputBuffer
                        }
                        if let conversionError { throw conversionError }
                        if status == .error { throw MicError.message("The microphone sample-rate conversion failed.") }
                        if let channel = converted.floatChannelData?[0] {
                            pending.append(contentsOf: UnsafeBufferPointer(start: channel, count: Int(converted.frameLength)))
                        }
                    } else if lastInput.duration(to: .now) > .seconds(3) {
                        throw MicError.message("No microphone audio arrived. Check microphone permission and the selected device.")
                    }
                    while pending.count >= AudioPipeline.hop && !Task.isCancelled {
                        let block = Array(pending.prefix(AudioPipeline.hop))
                        pending.removeFirst(AudioPipeline.hop)
                        let mark = ContinuousClock.now
                        let cleaned = try await processor.process(block, strength: controls.get())
                        try Task.checkCancellation()
                        let timing = mark.duration(to: .now).components
                        let milliseconds = Double(timing.seconds) * 1_000 + Double(timing.attoseconds) / 1e15
                        let clipped = cleaned.map { max(-1, min(1, $0)) }
                        let written = clipped.withUnsafeBufferPointer { outgoing.write($0.baseAddress!, count: $0.count) }
                        guard written == clipped.count else { throw MicError.message("The virtual audio output stopped consuming audio.") }
                        // A second hop absorbs callback phase and inference
                        // jitter. Starting with only one hop can starve a
                        // hardware render quantum even when inference is fast.
                        if !outputStarted, outgoing.count >= 2 * AudioPipeline.hop {
                            outgoing.arm()
                            outputStarted = true
                        }
                        if lastUpdate.duration(to: .now) > .milliseconds(100) {
                            lastUpdate = .now
                            let rms: ([Float]) -> Double = { x in sqrt(x.reduce(0) { $0 + Double($1 * $1) } / Double(max(1, x.count))) }
                            await update(AudioMetrics(inputLevel: rms(block), outputLevel: rms(cleaned), processingMS: milliseconds,
                                                      queueMS: Double(incoming.count) / rate * 1_000 + Double(outgoing.count) / 48,
                                                      underrunFrames: outgoing.underruns))
                        }
                    }
                    try await Task.sleep(for: .milliseconds(2))
                }
            } catch is CancellationError {
                // Stop is a normal user action.
            } catch {
                await failed(error.localizedDescription)
            }
        }
    }

    func stop() {
        worker?.cancel()
        worker = nil
        for token in notifications { NotificationCenter.default.removeObserver(token) }
        notifications.removeAll()
        inputEngine?.stop()
        inputEngine?.inputNode.removeTap(onBus: 0)
        outputEngine?.stop()
        inputEngine = nil
        outputEngine = nil
    }
}

func makeOutputSource(fifo: AudioFIFO, format: AVAudioFormat) -> AVAudioSourceNode {
    AVAudioSourceNode(format: format) { silence, _, frames, buffers in
        let list = UnsafeMutableAudioBufferListPointer(buffers)
        guard let destination = list.first?.mData?.assumingMemoryBound(to: Float.self) else { return noErr }
        let count = fifo.render(destination, count: Int(frames))
        silence.pointee = ObjCBool(count == 0)
        return noErr
    }
}

/// Exercise the app's actual output callback without opening a microphone or
/// writing to an installed audio device.
func checkOfflineRender() throws {
    let engine = AVAudioEngine()
    let format = AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: 1)!
    let fifo = AudioFIFO(capacity: 4_096)
    let samples = (0..<2_048).map { Float(sin(Double($0) * 0.04) * 0.2) }
    _ = samples.withUnsafeBufferPointer { fifo.write($0.baseAddress!, count: $0.count) }
    fifo.arm()
    let source = makeOutputSource(fifo: fifo, format: format)
    engine.attach(source)
    engine.connect(source, to: engine.mainMixerNode, format: format)
    try engine.enableManualRenderingMode(.offline, format: format, maximumFrameCount: 256)
    try engine.start()
    defer { engine.stop() }
    let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 256)!
    var rendered = [Float]()
    for _ in 0..<8 {
        guard try engine.renderOffline(256, to: buffer) == .success else { throw MicError.message("Offline audio rendering failed.") }
        rendered.append(contentsOf: UnsafeBufferPointer(start: buffer.floatChannelData![0], count: Int(buffer.frameLength)))
    }
    guard rendered.count == samples.count, zip(rendered, samples).allSatisfy({ abs($0 - $1) < 0.00001 }), fifo.underruns == 0 else {
        throw MicError.message("The rendered audio did not match the queued audio.")
    }
    print("Offline output render passed: 2048 frames, exact timeline, no underruns.")
}

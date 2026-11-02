import AVFoundation
import ClearMicModel
import Foundation

/// Opt-in integration check. Captures briefly into the live processing path,
/// saves no audio, and leaves default devices unchanged.
@MainActor func checkLiveAudioRecovery() async throws {
    guard await AVCaptureDevice.requestAccess(for: .audio) else {
        throw MicError.message("Allow Clear Mic in System Settings > Privacy & Security > Microphone before running the live check.")
    }
    let devices = AudioDevice.all()
    let inputUID = UserDefaults.standard.string(forKey: "inputUID") ?? "BuiltInMicrophoneDevice"
    let outputUID = UserDefaults.standard.string(forKey: "outputUID") ?? "BlackHole2ch_UID"
    guard let input = devices.first(where: { $0.uid == inputUID && $0.input && !$0.virtual }),
          let output = devices.first(where: { $0.uid == outputUID && $0.output && $0.virtual }) else {
        throw MicError.message("The selected physical microphone and virtual output must be connected for the live check.")
    }
    let processor = ClearProcessor(hop: AudioPipeline.hop)
    try await processor.prepare()
    var connectedDevices = devices
    let pipeline = AudioPipeline(availableDevices: { connectedDevices })
    defer { pipeline.stop() }
    var failure: String?
    var updates = 0
    var metrics = AudioMetrics()
    try pipeline.start(input: input, output: output, processor: processor,
                       update: { updates += 1; metrics = $0 }, failed: { failure = $0 })
    for phase in 0..<2 {
        let before = updates
        for _ in 0..<30 {
            try await Task.sleep(for: .milliseconds(100))
            if let failure { throw MicError.message(failure) }
        }
        guard updates > before + 5, let capture = pipeline.inputEngine,
              capture.isRunning, pipeline.outputEngine?.isRunning == true else {
            throw MicError.message("Live processing did not continue across the configuration change.")
        }
        print("Live phase \(phase + 1): hardware \(microphoneFormat(capture.inputNode).sampleRate) Hz, \(updates - before) metric updates, processing \(metrics.processingMS) ms, queue \(metrics.queueMS) ms.")
        if phase == 0 {
            // An unchanged startup notification must leave this graph intact.
            NotificationCenter.default.post(name: .AVAudioEngineConfigurationChange, object: capture)
            try await Task.sleep(for: .milliseconds(300))
            guard pipeline.inputEngine === capture, failure == nil else {
                throw MicError.message("An unchanged startup notification restarted a healthy capture engine.")
            }
            // A real engine stop must take the recovery path instead.
            capture.stop()
            NotificationCenter.default.post(name: .AVAudioEngineConfigurationChange, object: capture)
        }
    }
    let stoppedEngine = pipeline.inputEngine!
    pipeline.stop()
    NotificationCenter.default.post(name: .AVAudioEngineConfigurationChange, object: stoppedEngine)
    try await Task.sleep(for: .milliseconds(300))
    guard pipeline.inputEngine == nil, pipeline.outputEngine == nil else {
        throw MicError.message("A stale configuration event reopened a stopped microphone.")
    }
    // Simulate device removal at the inventory boundary without unplugging or
    // changing any of the user's actual audio hardware.
    failure = nil
    try pipeline.start(input: input, output: output, processor: processor,
                       update: { _ in }, failed: { failure = $0 })
    connectedDevices = []
    NotificationCenter.default.post(name: .AVAudioEngineConfigurationChange, object: pipeline.inputEngine!)
    try await Task.sleep(for: .milliseconds(400))
    guard failure?.contains("disconnected") == true, pipeline.inputEngine == nil, pipeline.outputEngine == nil else {
        throw MicError.message("A missing selected device did not stop capture and playback.")
    }
    print("Live capture, Clear processing, virtual playback, configuration recovery, Stop and simulated disconnection passed. No audio saved.")
}

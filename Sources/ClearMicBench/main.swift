import AVFoundation
import ClearMicCore
import ClearMicModel
import Foundation

func loadAudio(_ url: URL) throws -> [Float] {
    let file = try AVAudioFile(forReading: url)
    guard let input = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length)),
          let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 48_000, channels: 1, interleaved: false),
          let converter = AVAudioConverter(from: file.processingFormat, to: format),
          let output = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(Double(file.length) * 48_000 / file.processingFormat.sampleRate) + 1_024) else {
        throw NSError(domain: "ClearMicBench", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not create the audio converter."])
    }
    try file.read(into: input)
    var consumed = false
    var error: NSError?
    let status = converter.convert(to: output, error: &error) { _, state in
        if consumed { state.pointee = .endOfStream; return nil }
        consumed = true
        state.pointee = .haveData
        return input
    }
    if let error { throw error }
    guard status != .error, let samples = output.floatChannelData?[0] else { throw StreamError.shortOutput }
    return Array(UnsafeBufferPointer(start: samples, count: Int(output.frameLength)))
}

func writeAudio(_ samples: [Float], to url: URL) throws {
    let format = AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: 1)!
    let file = try AVAudioFile(forWriting: url, settings: format.settings)
    let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count))!
    buffer.frameLength = AVAudioFrameCount(samples.count)
    samples.withUnsafeBufferPointer { source in
        buffer.floatChannelData![0].update(from: source.baseAddress!, count: source.count)
    }
    try file.write(from: buffer)
}

@main struct Benchmark {
    static func main() async throws {
        guard CommandLine.arguments.count >= 3 else {
            print("Usage: ClearMicBench speech.aiff output-directory [hop-ms]")
            return
        }
        let source = URL(fileURLWithPath: CommandLine.arguments[1])
        let directory = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let hopMS = CommandLine.arguments.count > 3 ? Int(CommandLine.arguments[3]) ?? 40 : 40
        guard [20, 40, 80].contains(hopMS) else { throw StreamError.shortOutput }
        let hop = hopMS * 48
        let speech = try loadAudio(source)
        // Deterministic noise, plus quiet leading/trailing sections. No microphone
        // or user recording is needed to exercise the full processing path.
        let clean = Array(repeating: Float(0), count: 24_000) + Array(speech.prefix(48_000 * 8)) + Array(repeating: Float(0), count: 24_000)
        var seed: UInt64 = 7
        let noisy = clean.map { sample -> Float in
            seed = seed &* 6_364_136_223_846_793_005 &+ 1
            let noise = Float(seed >> 40) / Float(1 << 24) * 2 - 1
            return sample + noise * 0.025
        }
        let processor = ClearProcessor(hop: hop)
        let cold = ContinuousClock.now
        try await processor.prepare()
        let coldMS = milliseconds(since: cold)
        var output = [Float]()
        var timings = [Double]()
        let padded = noisy + Array(repeating: 0, count: (hop - noisy.count % hop) % hop + 4 * hop)
        for start in stride(from: 0, to: padded.count - hop + 1, by: hop) {
            let mark = ContinuousClock.now
            output += try await processor.process(Array(padded[start..<(start + hop)]))
            timings.append(milliseconds(since: mark))
        }
        let sorted = timings.sorted()
        let median = sorted[sorted.count / 2]
        let p95 = sorted[min(sorted.count - 1, Int(Double(sorted.count - 1) * 0.95))]
        let miss = timings.filter { $0 >= Double(hopMS) }.count
        guard output.allSatisfy(\.isFinite), output.count >= clean.count else { throw StreamError.nonfiniteOutput }
        func rms(_ values: ArraySlice<Float>) -> Double {
            sqrt(values.reduce(0) { $0 + Double($1) * Double($1) } / Double(max(1, values.count)))
        }
        let noiseBefore = rms(noisy[7_200..<19_200])
        let noiseAfter = rms(output[7_200..<19_200])
        let speechRMS = rms(output[48_000..<min(output.count, 192_000)])
        guard speechRMS > 0.001 else {
            throw NSError(domain: "ClearMicBench", code: 2, userInfo: [NSLocalizedDescriptionKey: "Processed speech is unexpectedly silent."])
        }
        try writeAudio(noisy, to: directory.appendingPathComponent("noisy.wav"))
        try writeAudio(output, to: directory.appendingPathComponent("cleaned.wav"))
        let report: [String: Any] = [
            "sdk_version": "4.1.0", "sample_rate": 48_000, "hop_ms": hopMS,
            "window_ms": 2_000, "lookahead_ms": 40, "crossfade_ms": 10,
            "warmup_ms": coldMS, "iterations": timings.count,
            "processing_median_ms": median, "processing_p95_ms": p95,
            "processing_max_ms": sorted.last!, "deadline_misses": miss,
            "buffering_plus_p95_ms": Double(hopMS + 50) + p95,
            "deadline_pass": miss == 0,
            "synthetic_noise_reduction_db": 20 * log10(max(noiseBefore, 1e-12) / max(noiseAfter, 1e-12)),
            "processed_speech_rms": speechRMS,
            "note": "Estimated software delay only. Hardware, routing and call-app delay are not measured. Sound quality requires listening."
        ]
        let json = try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
        try json.write(to: directory.appendingPathComponent("benchmark.json"))
        print(String(decoding: json, as: UTF8.self))
    }

    static func milliseconds(since start: ContinuousClock.Instant) -> Double {
        let parts = start.duration(to: .now).components
        return Double(parts.seconds) * 1_000 + Double(parts.attoseconds) / 1e15
    }
}

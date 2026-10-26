import Clear
import ClearMicCore
import DesertAnt
import Foundation

public actor ClearProcessor {
    private let clear: Clear
    private var window: StreamingWindow
    public init(hop: Int = 1_920) {
        DesertAnt.fasterNeuralEngineCompile = false
        clear = Clear()
        window = StreamingWindow(hop: hop)
    }

    public func prepare() async throws {
        // Keep private Core ML compilation APIs out of the app. Download and
        // warm before opening the microphone or starting the audio callbacks.
        try await clear.download()
        _ = try await clear.enhance(samples: Array(repeating: 0, count: 96_000), sampleRate: 48_000,
                                    options: .init(mastering: .bypass))
    }

    public func process(_ input: [Float], strength: Double = 1) async throws -> [Float] {
        let samples = window.append(input)
        if strength == 0 { return try window.extract(samples) }
        let result = try await clear.enhance(samples: samples, sampleRate: 48_000,
                                             options: .init(strength: .init(strength), mastering: .bypass))
        return try window.extract(result.samples)
    }
}

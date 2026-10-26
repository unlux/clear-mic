import Foundation

/// Experimental sliding inference. Each call includes past context and emits
/// only a short, delayed segment. This is not a stateful Clear model export.
public struct StreamingWindow {
    public static let sampleRate = 48_000
    public let hop: Int
    public let lookahead: Int
    public let overlap: Int
    public let context: Int
    private var history: [Float]
    private var tail: [Float]?

    public init(hop: Int = 1_920, lookahead: Int = 1_920, overlap: Int = 480, context: Int = 96_000) {
        precondition(hop > 0 && overlap > 0 && lookahead >= 0)
        precondition(hop >= overlap && context >= hop + overlap + lookahead)
        self.hop = hop
        self.lookahead = lookahead
        self.overlap = overlap
        self.context = context
        history = Array(repeating: 0, count: context)
    }

    public var bufferingMilliseconds: Double {
        Double(hop + lookahead + overlap) / Double(Self.sampleRate) * 1_000
    }

    public mutating func append(_ input: [Float]) -> [Float] {
        precondition(input.count == hop)
        history.removeFirst(hop)
        history.append(contentsOf: input.map { $0.isFinite ? $0 : 0 })
        return history
    }

    public mutating func extract(_ enhanced: [Float]) throws -> [Float] {
        guard enhanced.count >= context else { throw StreamError.shortOutput }
        let end = context - lookahead
        let begin = end - hop - overlap
        let segment = Array(enhanced[begin..<end])
        guard segment.allSatisfy(\.isFinite) else { throw StreamError.nonfiniteOutput }
        var output = Array(segment.prefix(hop))
        if let tail {
            for i in 0..<overlap {
                let weight = Float(i + 1) / Float(overlap + 1)
                output[i] = tail[i] * (1 - weight) + output[i] * weight
            }
        }
        tail = Array(segment.suffix(overlap))
        return output
    }
}

public enum StreamError: LocalizedError {
    case shortOutput, nonfiniteOutput
    public var errorDescription: String? {
        switch self {
        case .shortOutput: "Clear returned fewer samples than the processing window."
        case .nonfiniteOutput: "Clear returned invalid audio samples."
        }
    }
}

import XCTest
@testable import ClearMicCore

final class StreamingWindowTests: XCTestCase {
    func testIdentityProcessingPreservesTimelineAcrossWindows() throws {
        var stream = StreamingWindow(hop: 4, lookahead: 2, overlap: 2, context: 12)
        var rendered = [Float]()
        for block in 0..<5 {
            let input = (block * 4..<(block + 1) * 4).map { Float($0 + 1) }
            rendered += try stream.extract(stream.append(input))
        }
        // The saved crossfade tail and the next window refer to the same samples.
        XCTAssertEqual(rendered, [0, 0, 0, 0] + (1...16).map(Float.init))
    }

    func testCrossfadeUsesMatchingTimelineAndRejectsInvalidOutput() throws {
        var stream = StreamingWindow(hop: 4, lookahead: 2, overlap: 2, context: 12)
        _ = stream.append([1, 2, 3, 4])
        XCTAssertThrowsError(try stream.extract([1]))
        XCTAssertThrowsError(try stream.extract(Array(repeating: Float.nan, count: 12)))
        XCTAssertEqual(try stream.extract(Array(repeating: 0, count: 12)).count, 4)
    }

    func testNonfiniteInputIsSilenced() throws {
        var stream = StreamingWindow(hop: 4, lookahead: 0, overlap: 2, context: 8)
        XCTAssertTrue(stream.append([.nan, .infinity, -.infinity, 1]).allSatisfy(\.isFinite))
    }
}

import XCTest
@testable import ClearMicCore

final class AudioFIFOTests: XCTestCase {
    func testWrapAndOverflowPreserveOrder() {
        let fifo = AudioFIFO(capacity: 5)
        let first: [Float] = [1, 2, 3, 4]
        XCTAssertEqual(first.withUnsafeBufferPointer { fifo.write($0.baseAddress!, count: $0.count) }, 4)
        var buffer = [Float](repeating: 0, count: 3)
        XCTAssertEqual(buffer.withUnsafeMutableBufferPointer { fifo.read($0.baseAddress!, count: 3) }, 3)
        XCTAssertEqual(buffer, [1, 2, 3])
        let second: [Float] = [5, 6, 7, 8]
        XCTAssertEqual(second.withUnsafeBufferPointer { fifo.write($0.baseAddress!, count: 4) }, 4)
        XCTAssertEqual(second.withUnsafeBufferPointer { fifo.write($0.baseAddress!, count: 1) }, 0)
        XCTAssertEqual(fifo.dropped, 1)
        buffer = Array(repeating: 0, count: 5)
        XCTAssertEqual(buffer.withUnsafeMutableBufferPointer { fifo.read($0.baseAddress!, count: 5) }, 5)
        XCTAssertEqual(buffer, [4, 5, 6, 7, 8])
    }

    func testRenderStartsSilentThenFillsUnderrunsWithSilence() {
        let fifo = AudioFIFO(capacity: 8)
        var buffer: [Float] = [9, 9, 9, 9]
        XCTAssertEqual(buffer.withUnsafeMutableBufferPointer { fifo.render($0.baseAddress!, count: 4) }, 0)
        XCTAssertEqual(buffer, [0, 0, 0, 0])
        XCTAssertEqual(fifo.underruns, 0)
        let samples: [Float] = [0.25, -0.25]
        _ = samples.withUnsafeBufferPointer { fifo.write($0.baseAddress!, count: 2) }
        fifo.arm()
        XCTAssertEqual(buffer.withUnsafeMutableBufferPointer { fifo.render($0.baseAddress!, count: 4) }, 2)
        XCTAssertEqual(buffer, [0.25, -0.25, 0, 0])
        XCTAssertEqual(fifo.underruns, 2)
    }
}

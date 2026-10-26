import CAudioFIFO

/// One producer and one consumer. Destroy only after both callbacks have stopped.
public final class AudioFIFO: @unchecked Sendable {
    public let pointer: OpaquePointer
    public init(capacity: Int) {
        guard let pointer = cm_fifo_create(capacity) else { preconditionFailure("Could not allocate the audio queue.") }
        self.pointer = pointer
    }
    deinit { cm_fifo_destroy(pointer) }
    public var count: Int { cm_fifo_count(pointer) }
    public var dropped: UInt64 { cm_fifo_dropped(pointer) }
    public var underruns: UInt64 { cm_fifo_underruns(pointer) }
    public func write(_ source: UnsafePointer<Float>, count: Int) -> Int { cm_fifo_write(pointer, source, count) }
    public func read(_ destination: UnsafeMutablePointer<Float>, count: Int) -> Int { cm_fifo_read(pointer, destination, count) }
    public func render(_ destination: UnsafeMutablePointer<Float>, count: Int) -> Int { cm_fifo_render(pointer, destination, count) }
    public func arm() { cm_fifo_arm(pointer) }
}

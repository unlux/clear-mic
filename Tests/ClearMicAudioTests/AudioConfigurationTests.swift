import AVFoundation
import XCTest
@testable import ClearMic

final class AudioConfigurationTests: XCTestCase {
    func testCaptureUsesHardwareFormatWhenOutputFormatIsStale() throws {
        let engine = AVAudioEngine()
        let hardware = AVAudioFormat(standardFormatWithSampleRate: 96_000, channels: 1)!
        let stale = AVAudioFormat(standardFormatWithSampleRate: 48_000, channels: 1)!
        try engine.enableManualRenderingMode(.offline, format: stale, maximumFrameCount: 256)
        let input = engine.inputNode
        XCTAssertTrue(input.setManualRenderingInputPCMFormat(hardware) { _ in nil })
        engine.connect(input, to: engine.mainMixerNode, format: stale)
        XCTAssertEqual(input.inputFormat(forBus: 0).sampleRate, 96_000)
        XCTAssertEqual(input.outputFormat(forBus: 0).sampleRate, 48_000)
        XCTAssertEqual(microphoneFormat(input), hardware,
                       "Capture must use the selected device's hardware format, not the cached output format.")
    }
}

@MainActor final class AudioConfigurationObserverTests: XCTestCase {
    func testPairedNotificationsRequestOneRebuild() async throws {
        let center = NotificationCenter()
        let capture = AVAudioEngine(), playback = AVAudioEngine()
        var rebuilds = 0
        let observer = AudioConfigurationObserver(engines: [capture, playback], center: center,
                                                  settleTime: .milliseconds(5)) { rebuilds += 1 }
        defer { observer.stop() }
        center.post(name: .AVAudioEngineConfigurationChange, object: capture)
        center.post(name: .AVAudioEngineConfigurationChange, object: playback)
        try await Task.sleep(for: .milliseconds(50))
        XCTAssertEqual(rebuilds, 1, "A format notification must request recovery rather than report a disconnection.")
    }

    func testStopCancelsPendingAndQueuedNotifications() async throws {
        let center = NotificationCenter()
        let engine = AVAudioEngine()
        var rebuilds = 0
        let observer = AudioConfigurationObserver(engines: [engine], center: center,
                                                  settleTime: .milliseconds(30)) { rebuilds += 1 }
        center.post(name: .AVAudioEngineConfigurationChange, object: engine)
        await Task.yield()
        observer.stop()
        center.post(name: .AVAudioEngineConfigurationChange, object: engine)
        try await Task.sleep(for: .milliseconds(60))
        XCTAssertEqual(rebuilds, 0, "Stop must not reopen the microphone through a queued notification.")
    }

    func testUnrelatedEngineNotificationIsIgnored() async throws {
        let center = NotificationCenter()
        let engine = AVAudioEngine(), unrelated = AVAudioEngine()
        var rebuilds = 0
        let observer = AudioConfigurationObserver(engines: [engine], center: center,
                                                  settleTime: .milliseconds(5)) { rebuilds += 1 }
        defer { observer.stop() }
        center.post(name: .AVAudioEngineConfigurationChange, object: unrelated)
        try await Task.sleep(for: .milliseconds(30))
        XCTAssertEqual(rebuilds, 0)
    }
}

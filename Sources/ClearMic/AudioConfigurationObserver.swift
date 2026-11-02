import AVFoundation
import Foundation

/// Configuration notifications are format-change signals. Defer handling off
/// Core Audio's notification thread and coalesce paired engine notifications.
@MainActor final class AudioConfigurationObserver {
    private let center: NotificationCenter
    private var tokens: [NSObjectProtocol] = []
    private var pending: Task<Void, Never>?
    private var active = true

    init(engines: [AVAudioEngine], center: NotificationCenter = .default,
         settleTime: Duration = .milliseconds(200),
         changed: @escaping @MainActor @Sendable () -> Void) {
        self.center = center
        for engine in engines {
            tokens.append(center.addObserver(forName: .AVAudioEngineConfigurationChange, object: engine, queue: nil) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self, self.active, self.pending == nil else { return }
                    self.pending = Task { [weak self] in
                        do { try await Task.sleep(for: settleTime) }
                        catch { return }
                        guard let self, self.active else { return }
                        self.pending = nil
                        changed()
                    }
                }
            })
        }
    }

    func stop() {
        active = false
        pending?.cancel()
        pending = nil
        for token in tokens { center.removeObserver(token) }
        tokens.removeAll()
    }
}

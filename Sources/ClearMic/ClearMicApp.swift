import AVFoundation
import AppKit
import ClearMicModel
import Darwin
import SwiftUI

@MainActor final class MicModel: ObservableObject {
    @Published var devices: [AudioDevice] = []
    @Published var inputUID = ""
    @Published var outputUID = ""
    @Published var running = false
    @Published var preparing = false
    @Published var message = "Choose a microphone and virtual output."
    @Published var error: String?
    @Published var metrics = AudioMetrics()
    @Published var strength = 1.0 { didSet { updateControls() } }
    @Published var suppression = true { didSet { updateControls() } }
    private var pipeline: AudioPipeline?
    private var startTask: Task<Void, Never>?
    private var generation: UUID?
    private var termination: NSObjectProtocol?

    var inputs: [AudioDevice] { devices.filter { $0.input && !$0.virtual } }
    var outputs: [AudioDevice] { devices.filter { $0.output && $0.virtual } }
    var busy: Bool { running || preparing }
    var outputName: String { outputs.first { $0.uid == outputUID }?.name ?? "the virtual audio device" }
    var canStart: Bool { inputs.contains { $0.uid == inputUID } && outputs.contains { $0.uid == outputUID } }

    init() {
        inputUID = UserDefaults.standard.string(forKey: "inputUID") ?? ""
        outputUID = UserDefaults.standard.string(forKey: "outputUID") ?? ""
        refresh()
        termination = NotificationCenter.default.addObserver(forName: NSApplication.willTerminateNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.stop() }
        }
    }

    func refresh() {
        guard !busy else { return }
        devices = AudioDevice.all()
        if !inputs.contains(where: { $0.uid == inputUID }) {
            inputUID = inputs.first(where: { $0.name.localizedCaseInsensitiveContains("MacBook") })?.uid ?? inputs.first?.uid ?? ""
        }
        if !outputs.contains(where: { $0.uid == outputUID }) {
            // Never take over another effect app's device automatically.
            outputUID = outputs.first(where: { $0.name.localizedCaseInsensitiveContains("BlackHole") })?.uid ?? ""
        }
    }

    func start() {
        guard !busy, let input = inputs.first(where: { $0.uid == inputUID }),
              let output = outputs.first(where: { $0.uid == outputUID }) else { return }
        let token = UUID()
        generation = token
        error = nil
        metrics = AudioMetrics()
        preparing = true
        message = "Preparing Clear. The first run downloads and prepares the model."
        UserDefaults.standard.set(inputUID, forKey: "inputUID")
        UserDefaults.standard.set(outputUID, forKey: "outputUID")
        startTask = Task { [self] in
            do {
                let processor = ClearProcessor(hop: AudioPipeline.hop)
                try await processor.prepare()
                try Task.checkCancellation()
                guard generation == token else { return }
                message = "Allow microphone access to start."
                let allowed = await AVCaptureDevice.requestAccess(for: .audio)
                try Task.checkCancellation()
                guard generation == token else { return }
                guard allowed else { throw MicError.message("Allow Clear Mic in System Settings > Privacy & Security > Microphone, then start again.") }
                let audio = AudioPipeline()
                pipeline = audio
                updateControls()
                try audio.start(input: input, output: output, processor: processor, update: { [weak self] value in
                    guard self?.generation == token else { return }
                    self?.metrics = value
                }, failed: { [weak self] text in
                    guard self?.generation == token else { return }
                    self?.stop()
                    self?.error = text
                })
                preparing = false
                running = true
                message = "Sending microphone audio to \(output.name)."
            } catch is CancellationError {
                // Stopping during loading must not open the mic afterward.
            } catch {
                guard generation == token else { return }
                stop()
                self.error = error.localizedDescription
            }
        }
    }

    func stop() {
        generation = nil
        startTask?.cancel()
        startTask = nil
        pipeline?.stop()
        pipeline = nil
        running = false
        preparing = false
        message = "Stopped. The microphone is released."
        metrics = AudioMetrics()
    }

    private func updateControls() { pipeline?.controls.set(suppression ? strength : 0) }
}

struct ControlsView: View {
    @ObservedObject var model: MicModel
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                Image(systemName: model.running ? "mic.fill" : "mic").font(.system(size: 30)).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 5) {
                    Text("Clear Mic").font(.title2.bold())
                    Text("Clean microphone audio for your calls").foregroundStyle(.secondary)
                }
                Spacer()
                if model.preparing { ProgressView().controlSize(.small).accessibilityLabel("Preparing audio model") }
            }
            Form {
                Picker("Microphone", selection: $model.inputUID) {
                    if model.inputs.isEmpty { Text("No microphone found").tag("") }
                    ForEach(model.inputs) { Text($0.name).tag($0.uid) }
                }
                Picker("Virtual output", selection: $model.outputUID) {
                    Text("Choose a virtual device").tag("")
                    ForEach(model.outputs) { Text($0.name).tag($0.uid) }
                }
                Button("Refresh devices") { model.refresh() }
            }.disabled(model.busy)
            if model.outputUID.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("A virtual audio device connects Clear Mic to your call apps.")
                    Link("Get BlackHole for macOS", destination: URL(string: "https://existential.audio/blackhole/")!)
                    Text("If using an existing device, stop its other audio effect app first.").font(.caption).foregroundStyle(.secondary)
                }
                .padding(14).frame(maxWidth: .infinity, alignment: .leading).background(.quaternary, in: RoundedRectangle(cornerRadius: 10))
            }
            Toggle("Noise suppression", isOn: $model.suppression)
            HStack {
                Text("Strength")
                Slider(value: $model.strength, in: 0...1, step: 0.05).accessibilityLabel("Noise suppression strength")
                    .disabled(!model.suppression)
                Text(model.strength, format: .percent.precision(.fractionLength(0))).monospacedDigit().frame(width: 42, alignment: .trailing)
            }
            HStack(spacing: 24) {
                meter("Microphone", value: model.metrics.inputLevel)
                meter("Clean output", value: model.metrics.outputLevel)
            }
            if model.running {
                HStack {
                    Text("Processing \(model.metrics.processingMS, specifier: "%.1f") ms")
                    Spacer()
                    Text("Queue \(model.metrics.queueMS, specifier: "%.0f") ms")
                }.font(.caption.monospacedDigit()).foregroundStyle(.secondary)
                if model.metrics.underrunFrames > 0 {
                    Text("Output gaps detected. Try closing other audio effects.").font(.caption).foregroundStyle(.orange)
                }
            }
            Text(model.message).font(.callout).fixedSize(horizontal: false, vertical: true)
            if let error = model.error {
                Text(error).foregroundStyle(.red).textSelection(.enabled).fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel("Error: \(error)")
            }
            HStack {
                Button(model.busy ? "Stop microphone" : "Start microphone") {
                    if model.busy { model.stop() } else { model.start() }
                }
                .buttonStyle(.borderedProminent).controlSize(.large)
                .disabled(!model.busy && !model.canStart)
                .keyboardShortcut(.return, modifiers: [])
                Spacer()
                Text(model.running ? "Microphone active" : "Microphone off").font(.caption).foregroundStyle(.secondary)
            }
            Divider()
            VStack(alignment: .leading, spacing: 6) {
                Text("In Meet, Zoom or Discord, select \(model.outputName) as your microphone. Keep your normal headphones or speakers as the call output.")
                Text("Closing this window keeps Clear Mic running in the menu bar. Use Stop or Quit to release the microphone.")
                Text("Experimental live processing. Check delay and sound with a test call.")
            }.font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            Link("Powered by Desert Ant Labs", destination: URL(string: "https://desertant.com")!).font(.caption)
        }.padding(24).frame(width: 490).fixedSize(horizontal: false, vertical: true)
    }

    private func meter(_ label: String, value: Double) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(label)
                Spacer()
                Text(value > 0.00001 ? String(format: "%.0f dB", 20 * log10(value)) : "Silent").monospacedDigit()
            }.font(.caption)
            ProgressView(value: min(1, value * 5)).accessibilityLabel(label).accessibilityValue(value > 0.00001 ? String(format: "%.0f decibels", 20 * log10(value)) : "Silent")
        }.frame(maxWidth: .infinity)
    }
}

@main struct ClearMicApp: App {
    @StateObject private var model = MicModel()
    @Environment(\.openWindow) private var openWindow

    init() {
        if CommandLine.arguments.contains("--check-model") {
            Task.detached {
                do {
                    try await ClearProcessor(hop: AudioPipeline.hop).prepare()
                    print("Packaged Clear model loaded and warmed without microphone access.")
                    Darwin.exit(0)
                } catch {
                    fputs(error.localizedDescription + "\n", stderr)
                    Darwin.exit(1)
                }
            }
            dispatchMain()
        }
        if CommandLine.arguments.contains("--check-render") {
            do { try checkOfflineRender(); Darwin.exit(0) }
            catch { fputs(error.localizedDescription + "\n", stderr); Darwin.exit(1) }
        }
        if CommandLine.arguments.contains("--list-devices") {
            let data = try! JSONEncoder().encode(AudioDevice.all())
            print(String(decoding: data, as: UTF8.self))
            Darwin.exit(0)
        }
    }

    var body: some Scene {
        Window("Clear Mic", id: "controls") { ControlsView(model: model) }
            .windowResizability(.contentSize)
        MenuBarExtra("Clear Mic", systemImage: model.running ? "mic.fill" : "mic.slash") {
            Text(model.running ? "Microphone active" : "Microphone off")
            Button("Open controls") { openWindow(id: "controls"); NSApp.activate(ignoringOtherApps: true) }
            if model.busy { Button("Stop microphone") { model.stop() } }
            Divider()
            Button("Quit Clear Mic") { model.stop(); NSApp.terminate(nil) }.keyboardShortcut("q")
        }
    }
}

# Validation on 2026-10-26

Native host: MacBook Pro, Apple M5 Pro, 48 GB RAM, macOS 27.0.1, Swift 6.4.
Clear SDK is pinned to 4.1.0. Model preparation disables the SDK's private Core
ML compilation optimization. Checks use full Xcode through a per-process
`DEVELOPER_DIR`; the machine's global developer selection is unchanged.

Passed:

- Release app build and ad-hoc signature verification.
- Five XCTest cases, zero failures: cross-window identity/timeline, crossfade
  output validation, non-finite input, FIFO wrap/overflow, silent underruns.
- Packaged app's offline render check: 2,048 frames match the input, no underruns.
- Packaged app model download/load/warmup, without microphone access.
- Core Audio device enumeration, without microphone access.
- The final-build synthetic 20 ms benchmark: all 454 processing deadlines met.
  Median 6.98 ms, p95 7.81 ms, maximum 8.72 ms. Synthetic noise-only attenuation
  was 20.27 dB, with non-silent speech output. See the adjacent JSON.
- The fleet fixed checks through `finalize-code`: fleet tests, finalizer tests,
  and shell syntax. New build/check scripts also pass `bash -n`.

The benchmark's 77.81 ms buffering-plus-p95 figure excludes hardware, sample-rate
conversion, output reserve/queue, driver and call-app delay. The live pipeline
adds a 20 ms output reserve. Its end-to-end delay has not been measured.

Not verified:

- Microphone permission and live physical-microphone capture.
- Virtual-device routing or actual Meet, Zoom and Discord calls. Core Audio
  exposed no active virtual output device during validation. BlackHole needs
  separate installation and a Mac-side administrator prompt.
- VoiceOver interaction, subjective speech quality, battery consumption, long
  sessions and clock drift between separate capture/playback devices.

The benchmark audio was synthesized with macOS `say` and mixed with deterministic
noise. No personal recordings or live microphone audio were captured by checks.
The app is an experimental local build, not a validated replacement for a
production call-processing tool.

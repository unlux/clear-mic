# Clear Mic

An experimental native macOS microphone cleaner using Desert Ant Labs Clear
4.1.0. Select its virtual audio output as the microphone in Meet, Zoom or Discord.

The app has physical microphone selection, virtual output selection, suppression
strength, bypass, level meters, processing and queue metrics, and menu-bar stop
and quit controls. It starts with the microphone off. Closing the controls window
keeps an active session running; Stop or Quit releases the microphone.

## Run on the MacBook

Requires Apple silicon, macOS 15 or newer, and a virtual loopback device.
BlackHole is a separate audio driver, not included in this app.

1. Install the official two-channel BlackHole driver. With Homebrew:

   ```sh
   brew install --cask blackhole-2ch
   ```

   The installer can request the Mac administrator password and an audio-service
   restart. Finish an active call before installing. Follow any restart request.
2. Open Clear Mic. Select your physical microphone and BlackHole 2ch as output.
3. Select Start microphone and allow macOS microphone access.
4. In your call app, select BlackHole 2ch as the microphone. Keep the call's
   speaker output on your normal headphones or speakers.
5. Run a test call. Disable the call app's own noise suppression when comparing
   the result, and avoid running another microphone effect on the same device.

The first start downloads and prepares Clear. Later starts reuse the model
cache. If permission was denied, allow Clear Mic under System Settings >
Privacy & Security > Microphone. The app neither records nor saves live audio.
The SDK can make model-download and usage-licensing requests; audio inference
stays on the Mac. This is not a claim of zero network activity.

## Build and validate

Run on macOS with Swift 6.2 or newer. Full Xcode is not required on the tested
MacBook; the Command Line Tools supplied the SDK.

```sh
bash build-app.sh
bash check.sh
.build/release/ClearMic --check-render
.build/release/ClearMic --list-devices
open "dist/Clear Mic.app"
```

`build-app.sh` produces an ad-hoc signed local app. It includes Desert Ant's
license and third-party notices. This build is not notarized for public
distribution. The dependency and resolved revisions are pinned.

`check.sh` uses the installed full Xcode for XCTest, without changing the global
developer-directory setting. Standalone Command Line Tools can build the app
but do not supply XCTest. The check also loads the model from the packaged app.

The render check runs the app's actual source-node callback in offline rendering
mode. It compares the output against 2,048 known frames without microphone access
or device playback. Unit tests check streaming alignment, crossfade continuity,
FIFO wrap/overflow and silence on underrun.

## Latency experiment

The published Clear export processes independent two-second windows. Its SDK's
file-streaming mode is not a live-microphone interface. This prototype slides a
two-second history forward every 20 ms, runs the unmodified SDK, and emits only
the newest usable segment. It holds back 40 ms of right context and crossfades
10 ms of overlapping output. History is initially zero-filled, so the app does
not wait for two seconds of microphone input before producing output.

Processing runs off the audio callbacks. Single-producer/single-consumer C11
atomic FIFOs connect capture, the worker and output. The callbacks do no inference,
heap allocation or lock acquisition. The worker converts the microphone's sample
rate to 48 kHz and captures its first channel. Output is mono and is mapped by
the output mixer to the virtual device. Input and output defaults are not changed.

Whole-file loudness mastering is disabled. Bypass preserves the delayed timeline.
The worker stops on excessive backlog or lost capture instead of accumulating
seconds of delay. An output underrun inserts silence and exposes an on-screen
warning. Device changes stop the session and require an explicit restart.
Output starts after two hops are queued, adding 20 ms of reserve for callback
phase and inference jitter. The model-only benchmark does not include it.

To reproduce the synthetic benchmark without microphone access:

```sh
say -o /tmp/clear-mic-speech.aiff \
  "A quiet microphone should keep every word clear while removing the sound of fans and typing. This is a synthetic recording for a live audio experiment."
swift run -c release ClearMicBench /tmp/clear-mic-speech.aiff artifacts/bench-20ms 20
```

The benchmark adds deterministic noise, writes noisy and cleaned WAVs, checks
for finite and non-silent speech output, and reports warmup, processing
percentiles and deadline misses. Noise attenuation on synthetic silence is a
sanity check, not an intelligibility or speech-quality score.

Initial M5 Pro experiments met all 454 processing deadlines at a 20 ms hop.
The first run measured median 6.65 ms, p95 7.63 ms and maximum 8.22 ms. The
buffering-plus-p95 estimate was 77.63 ms. These figures exclude microphone
hardware, converter, queue, output-device and call-app delay. See `validation/`
for the final-build measurements and validation notes.

## Limits and remaining checks

Live microphone permission, BlackHole routing, subjective sound, long-session
clock drift and actual Meet/Zoom/Discord call delay still need a hands-on test.
The experiment establishes processing headroom, not a verified end-to-end latency
or sound-quality guarantee. Recomputing overlapping windows is less efficient
than a model exported for stateful real-time processing, and can change sound at
window boundaries despite the crossfade. Battery use has not been measured.

The app restricts outputs to virtual devices and inputs to physical microphones
to avoid accidentally monitoring a microphone through speakers. No driver is
installed, and no global audio defaults are changed by the build or checks.
Only synthetic audio is saved by the benchmark. Clear suppresses non-speech noise
but does not isolate a selected person from overlapping speakers.

## Sources and license

- [Clear documentation](https://desertant.com/docs/clear/)
- [Clear SDK source](https://github.com/Desert-Ant-Labs/desert-ant-core/tree/4.1.0/Sources/Clear)
- [Desert Ant license](https://license.desertant.com/1.0)
- [BlackHole setup and routing](https://github.com/ExistentialAudio/BlackHole)

Clear and its SDK are source-available under Desert Ant's license. Attribution is
visible in the app. Commercial distribution must respect its active-device
threshold, telemetry terms and upstream notices. BlackHole is independently
installed and licensed; this app does not bundle or modify its driver.

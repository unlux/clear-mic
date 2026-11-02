# Clear Mic

A native macOS microphone cleaner for Meet, Zoom, Discord and other apps that
accept an audio input device. Choose a physical microphone, clean it locally,
and send the result through a separately installed virtual audio driver.

Powered by [Desert Ant Labs](https://desertant.com). Speech enhancement uses its
Clear model and Swift SDK 4.1.0. Clear Mic is an independent project.

**License scope:** our application code is [MIT licensed](LICENSE). Desert Ant's
SDK/model keep their [source-available license](LICENSES/Desert-Ant-Labs-Source-Available-1.0.txt).
The full app and dependency bundle is not offered under MIT alone.

```text
Physical microphone -> Clear on your Mac -> BlackHole 2ch -> Call app
```

## Get started

Requires an Apple silicon Mac, macOS 15 or newer, and a virtual loopback device.
The tested setup is a MacBook Pro with an M5 Pro and BlackHole 2ch.

1. Install the official [BlackHole 2ch driver](https://existential.audio/blackhole/).
   With Homebrew, run `brew install --cask blackhole-2ch`. It is a separate
   installation, can request administrator approval, and is not bundled here.
2. Build from source below, or get the experimental arm64 archive from
   [Releases](https://github.com/unlux/clear-mic/releases). Move Clear Mic.app
   into your Applications folder and open it.
3. Select a physical microphone and BlackHole 2ch as the virtual output.
4. Read the in-app privacy and licenses notice, choose **Start microphone**,
   and allow microphone access in macOS.
5. In your call app, select **BlackHole 2ch** as its microphone. Keep its speaker
   output on your normal headphones or speakers. Make a test call.

The release is ad-hoc signed and is not notarized by Apple. macOS may prevent
it from opening. Build from source if you prefer to inspect and build it yourself;
review [Apple's guidance for opening apps](https://support.apple.com/en-us/102445) from outside the App Store. Do not
turn off system security protections to run this experiment.

The app starts with its microphone off. Closing the controls window keeps an
active session running in the menu bar. **Stop** releases the microphone;
**Quit** ends the app process. Startup configuration notifications keep healthy
streams running; changed/stopped streams recover, and lost devices stop capture.

## Controls

- Physical microphone and virtual output selection.
- Noise suppression toggle, strength slider and delayed bypass.
- Input/output level meters, processing/queue timings and output-gap warnings.
- Menu bar access, Stop and Quit.
- Offline privacy policy, terms and complete license texts inside the app.

## Privacy

Audio inference runs locally. Normal Clear Mic use saves no recordings and
uploads neither microphone audio nor cleaned audio. Receiving call apps can
record or transmit the virtual microphone under their own policies.

The SDK downloads its model from Hugging Face and makes licensing requests to
Desert Ant with a generated installation ID and app/model/SDK metadata. These
requests can begin during preparation, before microphone permission is granted.
There is no supported SDK telemetry opt-out. Stop releases audio devices but
can leave SDK background licensing work running until Quit.

Read the [privacy policy](PRIVACY.md) for destinations, fields, storage, retention,
controls and third-party processing. See [terms of use](TERMS.md) for the release's
scope and the separate software licenses. No account or subscription is required
by this Clear Mic release.

## Build

Use macOS with Swift 6.2 or newer. Command Line Tools can build the app; the
native XCTest suite requires full Xcode.

```sh
git clone https://github.com/unlux/clear-mic.git
cd clear-mic
bash build-app.sh
open "dist/Clear Mic.app"
```

The build pins dependency revisions in Package.resolved, preserves legal
materials and the SDK privacy bundle, and verifies its ad-hoc signature. Model
weights and the BlackHole driver are not included in the repository or archive.
On first Start, the model is downloaded and prepared before capture begins.

```sh
bash check.sh
```

Checks build the app, run XCTest, verify offline audio rendering, load the
packaged model, enumerate audio devices, and check bundled legal documents.
Model preparation can make the network requests in the privacy policy. The
standard check never opens the microphone. It selects full Xcode for that
process without changing the global developer-directory setting.

For a separate live integration check, stop any active Clear Mic session first:

```sh
bash check-live.sh "$PWD/dist/Clear Mic.app"
```

This opt-in check requests microphone permission if needed, processes briefly,
tests startup notifications, recovery, Stop and simulated disconnection, then
releases both devices. It saves no audio. It launches through macOS LaunchServices
so permission is associated with the app. Direct SSH execution has a different
permission context.

## How the audio path works

The published Clear export processes two-second windows. This app maintains a
sliding two-second context and advances it every 20 ms. It holds back 40 ms of
right context and crossfades 10 ms of overlapping output. History starts with
zeros, so the app does not wait two seconds before it starts producing output.

Inference runs away from the real-time audio callbacks. C11 atomic FIFOs connect
capture, processing and output. The callbacks do no inference, allocation or
locking. The worker captures the selected input's first channel, converts its
hardware sample rate to 48 kHz, and emits mono output to the virtual device.
Whole-file loudness mastering and the SDK's private Core ML compilation
optimization are disabled. Global input/output defaults are not changed.

Output begins after two hops are queued. Excessive backlog stops processing
instead of accumulating seconds of delay. Bypass preserves the delayed timeline.
Recomputing overlapping windows costs more than stateful streaming inference and
can change sound at window boundaries despite the crossfade.

## Validation and limits

Nine native tests and the live capture/processing/BlackHole recovery check passed
on the tested MacBook. The maintainer's listening test reported good voice quality
and negligible perceived delay. This is subjective feedback on one setup, not an
end-to-end latency measurement or a test of every call application.

A synthetic 20 ms benchmark met all 454 processing deadlines on the M5 Pro.
Its final median processing time was 6.98 ms, p95 7.81 ms and maximum 8.72 ms.
These measure model-processing headroom, excluding hardware, converter, queue,
driver and call-app delay. See [validation notes](validation/README.md).

Long sessions, clock drift across separate audio devices, battery use, broad
hardware compatibility and VoiceOver interaction remain unverified. Clear
suppresses non-speech noise; it does not isolate one person from overlapping
speakers. This remains an experimental local build.

The separate benchmark executable writes audio artifacts to the directory given
to it. Use synthesized or otherwise non-sensitive test audio. It is not part of
normal microphone use.

## Licenses, attribution and contributing

| Document | What it covers |
| --- | --- |
| [LICENSE](LICENSE) | MIT grant for original Clear Mic work |
| [Third-party notices](THIRD_PARTY_NOTICES.md) | Desert Ant, DeepFilterNet, Swift Numerics and separately installed BlackHole |
| [LICENSES](LICENSES/) | Preserved upstream license and copyright texts |
| [Privacy policy](PRIVACY.md) | Actual local processing and network/storage behavior |
| [Terms of use](TERMS.md) | Experimental release and upstream terms |
| [Security policy](SECURITY.md) | Private vulnerability reporting |
| [Contributing](CONTRIBUTING.md) | Development and validation |
| [Changelog](CHANGELOG.md) | Release changes |

Desert Ant's license permits embedding in an application, requires visible credit
and usage reporting, and has a free tier below 100,000 monthly active devices per
model per platform. Its competing-model training and other restrictions still
apply. See the full upstream license before redistributing or commercializing.

Source: [Clear documentation](https://desertant.com/docs/clear/),
[SDK](https://github.com/Desert-Ant-Labs/desert-ant-core/tree/86b9b55fe8c61ec1c27c5b6383f545c6df1d6ceb), and
[DeepFilterNet](https://github.com/Rikorose/DeepFilterNet).

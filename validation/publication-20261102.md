# Publication and legal review, 2 November 2026

Release 0.1.3 preserves the validated audio pipeline from 0.1.2 and adds legal
resources, an offline legal window, a startup networking disclosure and source
release metadata checks. Legal documents describe the inspected default build,
not a guarantee of jurisdiction-specific compliance or cleared training data.

The reviewed SDK is 4.1.0 at
`86b9b55fe8c61ec1c27c5b6383f545c6df1d6ceb`. The selected Clear model revision is
`v0.3.0`. The app's original code is MIT; the SDK/model remain source-available.

Primary-source review covered:

- [Full Desert Ant license](https://license.desertant.com/1.0.txt), including
  embedding, attribution, telemetry, commercial threshold and third-party terms.
- [Attribution guidance](https://license.desertant.com/attribution).
- [Pinned SDK licensing source](https://github.com/Desert-Ant-Labs/desert-ant-core/blob/86b9b55fe8c61ec1c27c5b6383f545c6df1d6ceb/Sources/Usage/Licensing.swift),
  its generated ID persistence, request bodies, retry/background behavior and
  model-store downloads. No real user preference payloads were inspected for
  this review.
- [Versioned Clear notice](https://huggingface.co/desert-ant-labs/clear/raw/v0.3.0/THIRD_PARTY_NOTICES.md),
  which records DeepFilterNet 3 fine-tuning and an MIT preservation notice.
- [DeepFilterNet MIT notice](https://github.com/Rikorose/DeepFilterNet/blob/main/LICENSE-MIT)
  and [Swift Numerics' resolved license](https://github.com/apple/swift-numerics/blob/0c0290ff6b24942dadb83a929ffaaa1481df04a2/LICENSE.txt).
- [BlackHole's separate licensing](https://github.com/ExistentialAudio/BlackHole/blob/master/LICENSE).
  No driver or official installer is bundled in this release.

The SDK-wide Clear provenance entry is incomplete. The model publisher's notice
fills in a base-model attribution but does not identify a checkpoint hash or
training-corpus inventory. Its 2022 copyright differs from the upstream project's
current 2021 MIT notice. Both notices are preserved verbatim; this is not a
certification of the training corpus or a correction of the publisher's notice.

Network disclosure includes the generated installation UUID, app/model/SDK
identity, platform label and license token, as well as ordinary transport
metadata. No telemetry opt-out, fixed server retention, deletion-on-uninstall,
or absence of all network activity is promised. Stop is distinguished from Quit.

Validation: native build, nine XCTest cases, packaged offline rendering, packaged
model preparation, device enumeration, legal resource verification and strict
signature verification passed on the development MacBook. Source metadata and
shell checks run locally and in CI. The earlier live pipeline and listening-test
results are documented separately. No new live microphone capture is required
for the legal/documentation change.

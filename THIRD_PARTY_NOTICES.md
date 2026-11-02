# Attribution and third-party notices

Clear Mic is an independent application by Lakshay Choudhary.
Copyright (c) 2026 Lakshay Choudhary. Original application code and documentation
are MIT licensed. That grant excludes separately licensed third-party materials.

## Desert Ant Labs Clear and Swift SDK

Powered by [Desert Ant Labs](https://desertant.com).
Clear speech enhancement is provided by Desert Ant Labs, not authored by Clear Mic.

- SDK `desert-ant-core` 4.1.0, revision
  `86b9b55fe8c61ec1c27c5b6383f545c6df1d6ceb`.
- Clear studio model revision `v0.3.0`, downloaded by the SDK at runtime.
- Copyright © 2026 Desert Ant Labs B.V.
- License: `LicenseRef-DAL-Source-Available-1.0`, source-available, not OSI open source.
- [SDK source](https://github.com/Desert-Ant-Labs/desert-ant-core/tree/86b9b55fe8c61ec1c27c5b6383f545c6df1d6ceb)
- [Model and model card](https://huggingface.co/desert-ant-labs/clear)
- [Authoritative license](https://license.desertant.com/1.0)
- [Attribution requirements](https://license.desertant.com/attribution)

The complete license is preserved in
[LICENSES/Desert-Ant-Labs-Source-Available-1.0.txt](LICENSES/Desert-Ant-Labs-Source-Available-1.0.txt).
The delivered SDK pointer/copyright notice and SDK-wide third-party notices are
preserved unchanged in `LICENSES/Desert-Ant-SDK-NOTICE.md` and
`LICENSES/Desert-Ant-Third-Party-Notices.md`. The SDK privacy resource bundle is
also retained in the packaged app.

Embedding the SDK and model in this application is subject to the upstream
license, including attribution and usage reporting. Its free tier is below
100,000 monthly active devices per model per platform, with commonly controlled
applications counted together. A commercial license is required when applicable.
For threshold or commercial questions, contact licensing@desertant.com. Do not
relicense or redistribute the model/SDK as an independent MIT product.

## DeepFilterNet 3

The model publisher states that Clear studio and natural are fine-tunes of
DeepFilterNet 3, DFN3-half configuration, on its speech corpus. DeepFilterNet is
by Hendrik Schröter and contributors. This attribution describes the publisher's
statement; Clear Mic has not audited the training corpus or checkpoint lineage.

The publisher's complete v0.3.0 preservation notice, including its 2022 copyright
and MIT license, is included unchanged in
[LICENSES/Clear-Model-Third-Party-Notices.md](LICENSES/Clear-Model-Third-Party-Notices.md).
The upstream project's MIT notice carrying its 2021 copyright is additionally
preserved in [LICENSES/DeepFilterNet-MIT.txt](LICENSES/DeepFilterNet-MIT.txt).
We retain both observed notices rather than changing either copyright year.

- [Publisher's versioned model notice](https://huggingface.co/desert-ant-labs/clear/raw/v0.3.0/THIRD_PARTY_NOTICES.md)
- [DeepFilterNet source](https://github.com/Rikorose/DeepFilterNet)

## Swift Numerics

The resolved dependency graph includes Apple Swift Numerics 1.1.1, revision
`0c0290ff6b24942dadb83a929ffaaa1481df04a2`. This does not assert that every resolved
package or module is linked into the Clear Mic executable.
Copyright Apple Inc. and the Swift Numerics project authors.

Its full Apache License 2.0 with Runtime Library Exception is included in
[LICENSES/Swift-Numerics-Apache-2.0.txt](LICENSES/Swift-Numerics-Apache-2.0.txt).
[Source and license](https://github.com/apple/swift-numerics/tree/0c0290ff6b24942dadb83a929ffaaa1481df04a2).

## BlackHole and system frameworks

[BlackHole](https://existential.audio/blackhole/) is a separate virtual audio
driver by Existential Audio Inc. Clear Mic does not include, modify or redistribute
its source, driver, official installer, artwork or trademarks. Obtain it from
its publisher. Its source is GPL v3; official binaries/installers and branding
have the publisher's separate notices. See
[BlackHole's current license](https://github.com/ExistentialAudio/BlackHole/blob/master/LICENSE).

Apple's SwiftUI, AppKit, AVFoundation, Core Audio, Core ML and other platform
frameworks are supplied by macOS and remain subject to Apple's terms. Linking to
system frameworks does not transfer ownership of them to Clear Mic.

## Distribution

The same notices and complete license texts ship in the app's `Contents/Resources/Legal`
directory and are available from its privacy and licenses window. GitHub's MIT
badge applies to Clear Mic's own work, not the entire dependency bundle. Changes
to dependencies require a new notice and privacy review.

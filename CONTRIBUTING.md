# Contributing

Open an issue for a bug or proposed change, or submit a pull request with a short
explanation and relevant validation. Use synthetic audio for reproducible tests.
Do not attach private recordings, credentials or SDK licensing identifiers.

Run `bash check.sh` on an Apple silicon Mac with full Xcode for the native tests.
It builds the release app, runs XCTest, and checks the packaged renderer, model
preparation, device enumeration and bundled legal documents. Model preparation
can download files and send the licensing metadata described in PRIVACY.md.
No microphone is opened by this standard check. The separate `check-live.sh`
uses microphone permission, captures briefly, and releases the audio devices.

Changes to dependencies, network behavior or storage must update the relevant
privacy and third-party notices. Keep the upstream license, privacy resource
bundle and user-visible Desert Ant credit intact. Contributions to original
Clear Mic code are offered under the repository's MIT license unless explicitly
agreed otherwise; this does not relicense third-party material.

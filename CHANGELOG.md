# Changelog

## 0.1.3, 2 November 2026

- First standalone public repository and experimental release.
- Add a privacy policy, terms of use, MIT license for original app code, and
  complete upstream license and attribution notices.
- Add an offline privacy and licenses window and startup network disclosure.
- Include legal documents, model provenance notices and privacy manifests in
  the packaged app, with a packaged-resource verification command.

## 0.1.2, 2 November 2026

- Use the selected microphone's hardware format rather than its stale cached
  engine output format, including 96 kHz microphone capture.
- Keep healthy streams running through delayed startup notifications.
- Recover stopped or changed audio graphs with bounded retries; stop safely
  on device loss and discard callbacks from previous graphs.
- Add native format/notification tests and a live recovery diagnostic.

## 0.1.0, 26 October 2026

- Initial macOS microphone cleaner using Desert Ant Labs Clear 4.1.0,
  a 20 ms processing hop and separate virtual audio output.

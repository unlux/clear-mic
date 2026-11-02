#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
if [[ "$(uname -s)" != Darwin ]]; then
  echo "Build Clear Mic on macOS with Swift 6.2 or newer." >&2
  exit 1
fi
swift build -c release --product ClearMic
app="dist/Clear Mic.app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
install -m 755 .build/release/ClearMic "$app/Contents/MacOS/ClearMic"
install -m 644 Info.plist "$app/Contents/Info.plist"
upstream=.build/checkouts/desert-ant-core
install -m 644 "$upstream/LICENSE.md" "$app/Contents/Resources/Desert-Ant-License.md"
install -m 644 "$upstream/THIRD_PARTY_NOTICES.md" "$app/Contents/Resources/Desert-Ant-Third-Party-Notices.md"
# Ship the same policies and complete notices as the source release.
mkdir -p "$app/Contents/Resources/Legal/LICENSES"
for document in LICENSE PRIVACY.md TERMS.md THIRD_PARTY_NOTICES.md; do
  install -m 644 "$document" "$app/Contents/Resources/Legal/$document"
done
for license in LICENSES/*; do
  install -m 644 "$license" "$app/Contents/Resources/Legal/LICENSES/$(basename "$license")"
done
install -m 644 PrivacyInfo.xcprivacy "$app/Contents/Resources/PrivacyInfo.xcprivacy"
# SwiftPM may emit resource bundles beside the executable.
for bundle in .build/release/*.bundle; do
  [[ -d "$bundle" ]] || continue
  ditto "$bundle" "$app/Contents/Resources/$(basename "$bundle")"
done
codesign --force --sign - "$app"
codesign --verify --strict "$app"
"$app/Contents/MacOS/ClearMic" --check-notices
printf 'Built %s/%s\n' "$PWD" "$app"

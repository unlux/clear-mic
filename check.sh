#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
python3 scripts/check-distribution.py
if [[ "$(uname -s)" != Darwin ]]; then
  echo "Run the native checks on macOS." >&2
  exit 1
fi
# XCTest ships in full Xcode, not the standalone Command Line Tools. Select
# Xcode for this process only; leave the machine's xcode-select setting alone.
if [[ -z "${DEVELOPER_DIR:-}" && -d /Applications/Xcode.app/Contents/Developer ]]; then
  export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
fi
xcrun --find xctest >/dev/null
bash build-app.sh
xcrun swift test
"dist/Clear Mic.app/Contents/MacOS/ClearMic" --check-notices
"dist/Clear Mic.app/Contents/MacOS/ClearMic" --check-render
"dist/Clear Mic.app/Contents/MacOS/ClearMic" --check-model
"dist/Clear Mic.app/Contents/MacOS/ClearMic" --list-devices

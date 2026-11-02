#!/usr/bin/env bash
set -euo pipefail
if [[ "$(uname -s)" != Darwin ]]; then
  echo "Run the live audio check on macOS." >&2
  exit 1
fi
app="${1:-$HOME/Applications/Clear Mic.app}"
result=$(mktemp -t clear-mic-live)
trap 'rm -f "$result"' EXIT
# LaunchServices gives the diagnostic the app's microphone permission context.
# Running its executable directly over SSH uses a different responsible process.
if ! open -W -n --stdout "$result" --stderr "$result" "$app" --args --check-live-recovery; then
  cat "$result"
  exit 1
fi
cat "$result"
grep -Fq 'Stop and simulated disconnection passed. No audio saved.' "$result"

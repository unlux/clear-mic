# Device recovery on 2026-11-02

Clear Mic 0.1.2, Clear SDK 4.1.0, MacBook Pro with BlackHole 2ch.

The built-in microphone reports 96 kHz immediately after selection while the
input node's cached output still reports 48 kHz. The old tap used the cached
format. Core Audio logged a format mismatch and then a configuration notification,
which the app reported as a disconnection. A native offline regression reproduced
the 96/48 kHz mismatch before the fix and passes using the hardware input format.

A second live reproduction found that device selection also sends a delayed
configuration notification when the graph is already healthy. Rebuilding on every
notification repeats that notification until the retry limit stops capture.
Recovery now checks device identity, hardware formats and engine state first.
Healthy streams continue. Changed or stopped streams rebuild after 200 ms, using
the same device UIDs. Missing devices stop the session. Three rebuilds within ten
seconds cap repeated changes. Stop invalidates both graph and session callbacks.

Native checks passed:

- Nine XCTest cases, including stale capture format, paired configuration
  notifications, pending restart cancellation and unrelated engine events.
- Packaged offline rendering, model preparation and device enumeration.
- Release build and strict ad-hoc signature verification.

The optional live check runs through LaunchServices to use the app's microphone
permission context. Direct SSH execution has a different responsible process.
It captures briefly, saves no audio, checks an unchanged notification, stops an
engine and verifies recovery, verifies Stop against a stale event, and simulates
selected-device removal at the device-inventory boundary.

Live check passed on the installed 0.1.2 build. The selected input ran at 96 kHz;
the two three-second phases produced 27 and 26 metric updates. The last processing
times were 13.39 and 11.01 ms, with queues of 41.33 and 58.67 ms. These are brief
live samples, not latency percentiles. Both engines were released at completion.
No personal audio was saved. The fleet fixed checks also passed through
`finalize-code`.
Actual Meet, Zoom and Discord calls, subjective quality, end-to-end latency and
long-session drift remain unverified.

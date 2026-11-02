#!/usr/bin/env python3
"""Check source-release metadata, policy links and required legal materials."""
import json
from pathlib import Path
import plistlib
import re

root = Path(__file__).resolve().parents[1]
required = [
    "LICENSE", "PRIVACY.md", "TERMS.md", "THIRD_PARTY_NOTICES.md", "SECURITY.md",
    "CONTRIBUTING.md", "CHANGELOG.md", "PrivacyInfo.xcprivacy",
    "LICENSES/Desert-Ant-Labs-Source-Available-1.0.txt",
    "LICENSES/Desert-Ant-SDK-NOTICE.md", "LICENSES/Desert-Ant-Third-Party-Notices.md",
    "LICENSES/Clear-Model-Third-Party-Notices.md", "LICENSES/DeepFilterNet-MIT.txt",
    "LICENSES/Swift-Numerics-Apache-2.0.txt",
]
for name in required:
    if not (root / name).read_bytes().strip():
        raise SystemExit(f"Empty required distribution file: {name}")

with (root / "Info.plist").open("rb") as file:
    info = plistlib.load(file)
if info["CFBundleIdentifier"] != "dev.unlux.clearmic":
    raise SystemExit("App identity changed; review privacy and licensing disclosures.")
if f"## {info['CFBundleShortVersionString']}," not in (root / "CHANGELOG.md").read_text():
    raise SystemExit("The app version needs a changelog entry.")

pins = {pin["identity"]: pin["state"] for pin in json.loads((root / "Package.resolved").read_text())["pins"]}
expected = {
    "desert-ant-core": ("4.1.0", "86b9b55fe8c61ec1c27c5b6383f545c6df1d6ceb"),
    "swift-numerics": ("1.1.1", "0c0290ff6b24942dadb83a929ffaaa1481df04a2"),
}
if set(pins) != set(expected) or any(
    (pins[name].get("version"), pins[name].get("revision")) != state
    for name, state in expected.items()
):
    raise SystemExit("Dependencies changed; review upstream notices and privacy before updating this baseline.")

with (root / "PrivacyInfo.xcprivacy").open("rb") as file:
    manifest = plistlib.load(file)
if manifest["NSPrivacyTracking"]:
    raise SystemExit("Tracking declaration changed; review the privacy policy.")
if "CA92.1" not in manifest["NSPrivacyAccessedAPITypes"][0]["NSPrivacyAccessedAPITypeReasons"]:
    raise SystemExit("The app must declare its own UserDefaults access.")

# Check links we author. Delivered upstream notices are preserved verbatim,
# including their original source-relative links.
for name in ["README.md", "PRIVACY.md", "TERMS.md", "THIRD_PARTY_NOTICES.md"]:
    for target in re.findall(r"\[[^\]]*\]\(([^\s)]+)\)", (root / name).read_text()):
        if ":" in target or target.startswith("#"):
            continue
        if not (root / target.split("#", 1)[0]).exists():
            raise SystemExit(f"Broken local link in {name}: {target}")
print(f"Distribution checks passed: {len(required)} required files, pinned dependencies, privacy manifest and policy links.")

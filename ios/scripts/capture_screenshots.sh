#!/bin/bash
# Capture App Store screenshots for one simulator device.
#
#   ios/scripts/capture_screenshots.sh "iPhone 17 Pro Max" iphone-6.9
#   ios/scripts/capture_screenshots.sh "iPad Pro 13-inch (M5)" ipad-13
#
# Boots the simulator, pins the status bar to the canonical 9:41 /
# full-battery look, runs ScreenshotTest, and exports the captures to
# ios/screenshots/<label>/.
set -euo pipefail

DEVICE="${1:?simulator device name}"
LABEL="${2:?output folder label}"
IOS_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="$IOS_DIR/screenshots/$LABEL"
RESULT_BUNDLE="$(mktemp -d)/capture.xcresult"

cd "$IOS_DIR"

xcrun simctl boot "$DEVICE" 2>/dev/null || true
xcrun simctl bootstatus "$DEVICE" >/dev/null
xcrun simctl status_bar "$DEVICE" override \
  --time "9:41" --batteryState charged --batteryLevel 100 \
  --cellularMode active --cellularBars 4 --wifiBars 3 --operatorName ""

xcodebuild -project ColorVisionTest.xcodeproj -scheme ColorVisionTest \
  -destination "platform=iOS Simulator,name=$DEVICE" \
  -only-testing:ColorVisionTestUITests/ScreenshotTest \
  -resultBundlePath "$RESULT_BUNDLE" \
  -derivedDataPath build test

xcrun simctl status_bar "$DEVICE" clear

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"
EXPORT_DIR="$(mktemp -d)"
xcrun xcresulttool export attachments --path "$RESULT_BUNDLE" --output-path "$EXPORT_DIR" >/dev/null

# manifest.json maps exported file names back to the XCTAttachment
# names ("01-hero", ...). Copy them out under those names.
python3 - "$EXPORT_DIR" "$OUT_DIR" <<'PY'
import json, shutil, sys
from pathlib import Path

export_dir, out_dir = Path(sys.argv[1]), Path(sys.argv[2])
manifest = json.loads((export_dir / "manifest.json").read_text())
count = 0
for test in manifest:
    for att in test.get("attachments", []):
        name = att.get("suggestedHumanReadableName") or att["exportedFileName"]
        # exported names look like "01-hero_0_<UUID>.png" — keep the
        # attachment name we set in ScreenshotTest.
        stem = Path(name).stem.split("_0_")[0]
        src = export_dir / att["exportedFileName"]
        dst = out_dir / (stem + ".png")
        shutil.copy(src, dst)
        count += 1
        print(f"  {dst.name}")
print(f"{count} screenshots -> {out_dir}")
PY

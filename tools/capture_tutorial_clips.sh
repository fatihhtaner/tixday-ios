#!/bin/zsh
# Records the raw clips for the tutorial videos (TikTok / Reels / Shorts) on a dedicated simulator.
# Usage: tools/capture_tutorial_clips.sh <lang> <locale> <out-dir>
# Create the simulator once: xcrun simctl create "Tixday Video" "iPhone 17 Pro Max". Needs a Debug build in build/.
# Clips: create (empty home → new Tokyo trip saved), widgets (that trip on Home Screen widgets),
# birthday (empty home → yearly birthday saved → its details), christmas (empty home → yearly Christmas
# train ticket saved) and christmas-widgets (it on Home Screen widgets).
set -e
LANG_CODE=$1 LOCALE=$2 OUT=$3
D="${SIM:-Tixday Video}"
APP=com.ibrahimfatihtaner.tixday
BUILD=$(cd "$(dirname "$0")/.." && pwd)/build/Build/Products/Debug-iphonesimulator/Tixday.app
mkdir -p "$OUT"

# The simulator's own language too, so system text (Home Screen, alerts) matches the video.
xcrun simctl boot "$D" 2>/dev/null || true
xcrun simctl bootstatus "$D" -b >/dev/null
xcrun simctl spawn "$D" defaults write -g AppleLanguages -array "$LANG_CODE"
xcrun simctl spawn "$D" defaults write -g AppleLocale "$LOCALE"
xcrun simctl shutdown "$D"
xcrun simctl boot "$D"
xcrun simctl bootstatus "$D" -b >/dev/null
xcrun simctl ui "$D" content_size large
xcrun simctl status_bar "$D" override --time "9:41" --batteryState discharging --batteryLevel 100 \
  --cellularMode active --cellularBars 4 --wifiBars 3 --operatorName ""
# A fresh install: empty store, onboarding marked done so home opens straight away.
xcrun simctl uninstall "$D" $APP 2>/dev/null || true
xcrun simctl install "$D" "$BUILD"

ARGS=(-proScreenshots -AppleLanguages "($LANG_CODE)" -AppleLocale "$LOCALE" didFinishOnboarding YES)
launch() { xcrun simctl terminate "$D" $APP 2>/dev/null || true; xcrun simctl launch "$D" $APP "${ARGS[@]}" "$@" >/dev/null; }
# record <name> <seconds> <command…>: starts recording, runs the command, stops after <seconds>.
record() {
  local name=$1 seconds=$2; shift 2
  rm -f "$OUT/$name.mp4"
  xcrun simctl io "$D" recordVideo --codec h264 --force "$OUT/$name.mp4" >/dev/null 2>&1 &
  local pid=$!
  sleep 1.5
  "$@"
  sleep "$seconds"
  kill -INT $pid; wait $pid 2>/dev/null || true
}

# Episode 1
record create 17 launch -screenshotScreen create-demo   # empty home, editor types the trip, saves
record widgets 10 launch -screenshotScreen my-widgets     # the new trip as Home Screen widgets
# Episode 2 starts empty again: a birthday that repeats every year, then its details.
xcrun simctl uninstall "$D" $APP
xcrun simctl install "$D" "$BUILD"
record birthday 24 launch -screenshotScreen birthday-demo
# Episode 3, empty again: Christmas as a yearly train ticket, then on Home Screen widgets.
xcrun simctl uninstall "$D" $APP
xcrun simctl install "$D" "$BUILD"
record christmas 20 launch -screenshotScreen christmas-demo
record christmas-widgets 10 launch -screenshotScreen my-widgets
echo "recorded $LANG_CODE"

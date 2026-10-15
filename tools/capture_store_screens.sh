#!/bin/zsh
# Captures the raw App Store screens on the iPhone 17 Pro Max simulator (6.9-inch), per language.
# Usage: tools/capture_store_screens.sh <out-dir> [lang:locale …]
#   e.g. tools/capture_store_screens.sh /tmp/shots en:en_US tr:tr_TR
# Without languages it captures all twelve. Needs a Debug build in build/ (see CLAUDE.md).
# Writes <out-dir>/<lang>/{home,widgets,birthday,editor,used}.png
set -e
OUT=$1; shift
LANGS=("$@")
(( ${#LANGS} )) || LANGS=(en:en_US tr:tr_TR de:de_DE fr:fr_FR es:es_ES it:it_IT pt-BR:pt_BR ja:ja_JP ko:ko_KR zh-Hans:zh_CN ru:ru_RU ar:ar_SA)
D="iPhone 17 Pro Max"
APP=com.ibrahimfatihtaner.tixday
BUILD=$(cd "$(dirname "$0")/.." && pwd)/build/Build/Products/Debug-iphonesimulator/Tixday.app

xcrun simctl boot "$D" 2>/dev/null || true
xcrun simctl bootstatus "$D" -b >/dev/null
xcrun simctl status_bar "$D" override --time "9:41" --batteryState discharging --batteryLevel 100 \
  --cellularMode active --cellularBars 4 --wifiBars 3 --operatorName ""
# Fresh sample tickets, dated from today.
xcrun simctl uninstall "$D" $APP 2>/dev/null || true
xcrun simctl install "$D" "$BUILD"

for pair in $LANGS; do
  lang=${pair%%:*} locale=${pair#*:}
  mkdir -p "$OUT/$lang"
  shot() {
    xcrun simctl terminate "$D" $APP 2>/dev/null || true
    xcrun simctl launch "$D" $APP -sampleData -proScreenshots -AppleLanguages "($lang)" -AppleLocale "$locale" "${@:2}" >/dev/null
    sleep 5
    xcrun simctl io "$D" screenshot "$OUT/$lang/$1.png" >/dev/null 2>&1
  }
  shot home
  shot widgets -screenshotScreen widgets
  shot birthday -screenshotScreen detail-birthday
  shot editor -screenshotScreen editor
  shot used -screenshotScreen detail-used
  echo "captured $lang"
done

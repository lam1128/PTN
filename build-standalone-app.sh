#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$ROOT_DIR/dist/PTNHypercubeWidget.app"
EXECUTABLE="$APP_DIR/Contents/MacOS/PTNHypercubeWidget"
MODULE_CACHE="/private/tmp/swift-module-cache"

mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources" "$MODULE_CACHE"

swiftc \
  -module-cache-path "$MODULE_CACHE" \
  "$ROOT_DIR/PTNHypercubeWidget/App/PTNHypercubeWidgetApp.swift" \
  "$ROOT_DIR/PTNHypercubeWidget/Models/RewardModels.swift" \
  "$ROOT_DIR/PTNHypercubeWidget/RewardEngine/RewardSchedule.swift" \
  "$ROOT_DIR/PTNHypercubeWidget/RewardEngine/RewardEngine.swift" \
  "$ROOT_DIR/PTNHypercubeWidget/Storage/AppStateStore.swift" \
  "$ROOT_DIR/PTNHypercubeWidget/Views/MainWidgetView.swift" \
  "$ROOT_DIR/PTNHypercubeWidget/Views/Sheets.swift" \
  -o "$EXECUTABLE"

chmod +x "$EXECUTABLE"
plutil -lint "$APP_DIR/Contents/Info.plist" >/dev/null

if command -v codesign >/dev/null 2>&1; then
  codesign --force --sign - "$APP_DIR" >/dev/null 2>&1 || true
fi

pkill -x PTNHypercubeWidget >/dev/null 2>&1 || true
sleep 0.3
open "$APP_DIR"

echo "Built standalone app at: $APP_DIR"

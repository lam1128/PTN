#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_DIR="$ROOT_DIR/dist/PTNHypercubeWidget.app"
EXECUTABLE="$APP_DIR/Contents/MacOS/PTNHypercubeWidget"
MODULE_CACHE="/private/tmp/swift-module-cache"
ENTITLEMENTS="$ROOT_DIR/PTNHypercubeWidget/App/PTNHypercubeWidgetMac.entitlements"

mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources" "$MODULE_CACHE"
SWIFT_SOURCES=("$ROOT_DIR"/PTNHypercubeWidget/**/*.swift(N))

swiftc \
  -module-cache-path "$MODULE_CACHE" \
  "${SWIFT_SOURCES[@]}" \
  -o "$EXECUTABLE"

chmod +x "$EXECUTABLE"

cat > "$APP_DIR/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0//EN">
<plist version="1.0"><dict>
<key>CFBundleDisplayName</key><string>异方晶</string>
<key>CFBundleExecutable</key><string>PTNHypercubeWidget</string>
<key>CFBundleIdentifier</key><string>com.openai.PTNHypercubeWidget</string>
<key>CFBundleName</key><string>PTNHypercubeWidget</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>1.0</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSApplicationCategoryType</key><string>public.app-category.utilities</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>LSUIElement</key><true/>
<key>NSHighResolutionCapable</key><true/>
<key>NSPrincipalClass</key><string>NSApplication</string>
</dict></plist>
PLIST

plutil -lint "$APP_DIR/Contents/Info.plist" >/dev/null

if command -v codesign >/dev/null 2>&1; then
  codesign --force --sign "${CODESIGN_IDENTITY:--}" --entitlements "$ENTITLEMENTS" "$APP_DIR" >/dev/null 2>&1 || true
fi

pkill -x PTNHypercubeWidget >/dev/null 2>&1 || true
sleep 0.3
# Refresh Launch Services so the newly generated bundle is the one opened.
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
if [[ -x "$LSREGISTER" ]]; then
  "$LSREGISTER" -u "$APP_DIR" >/dev/null 2>&1 || true
  "$LSREGISTER" -f "$APP_DIR" >/dev/null 2>&1 || true
fi
if ! /usr/bin/open -n "$APP_DIR"; then
  # Launch the freshly built executable if Launch Services has not indexed the bundle yet.
  "$EXECUTABLE" >/dev/null 2>&1 &
fi

echo "Built standalone app at: $APP_DIR"

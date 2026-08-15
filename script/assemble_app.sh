#!/bin/zsh

set -euo pipefail

CONFIGURATION="${1:-release}"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="PTNHypercubeWidget"
BUNDLE_ID="com.openai.PTNHypercubeWidget"
APP_BUNDLE="${2:-$ROOT_DIR/dist/$APP_NAME.app}"

case "$CONFIGURATION" in
    debug|release) ;;
    *)
        echo "用法: $0 [debug|release] [output.app]" >&2
        exit 2
        ;;
esac

cd "$ROOT_DIR"
swift build -c "$CONFIGURATION"
BIN_PATH="$(swift build -c "$CONFIGURATION" --show-bin-path)"
BUILD_BINARY="$BIN_PATH/$APP_NAME"

[[ -x "$BUILD_BINARY" ]] || {
    echo "找不到可执行文件: $BUILD_BINARY" >&2
    exit 3
}

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"
cp "$BUILD_BINARY" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

cat > "$APP_BUNDLE/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleDisplayName</key><string>异方晶</string>
<key>CFBundleExecutable</key><string>$APP_NAME</string>
<key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
<key>CFBundleName</key><string>异方晶</string>
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

plutil -lint "$APP_BUNDLE/Contents/Info.plist" >/dev/null

if command -v codesign >/dev/null 2>&1; then
    codesign --force --deep --sign - --identifier "$BUNDLE_ID" "$APP_BUNDLE" >/dev/null 2>&1 || true
fi

echo "$APP_BUNDLE"

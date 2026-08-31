#!/bin/zsh

set -euo pipefail

CONFIGURATION="${1:-release}"
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="PTNHypercubeWidget"
BUNDLE_ID="com.openai.PTNHypercubeWidget"
APP_BUNDLE="${2:-$ROOT_DIR/dist/$APP_NAME.app}"
ENTITLEMENTS="$ROOT_DIR/PTNHypercubeWidget/App/PTNHypercubeWidgetMac.entitlements"
OUTPUT_DIR="$(dirname "$APP_BUNDLE")"

case "$CONFIGURATION" in
    debug|release) ;;
    *)
        echo "用法: $0 [debug|release] [output.app]" >&2
        exit 2
        ;;
esac

cd "$ROOT_DIR"
swift build -c "$CONFIGURATION" -Xswiftc -DSTANDALONE_BUILD
BIN_PATH="$(swift build -c "$CONFIGURATION" --show-bin-path)"
BUILD_BINARY="$BIN_PATH/$APP_NAME"

[[ -x "$BUILD_BINARY" ]] || {
    echo "找不到可执行文件: $BUILD_BINARY" >&2
    exit 3
}

mkdir -p "$OUTPUT_DIR"
STAGING_ROOT="$(mktemp -d "$OUTPUT_DIR/.${APP_NAME}.build.XXXXXX")"
STAGING_APP="$STAGING_ROOT/$APP_NAME.app"
trap 'rm -rf "$STAGING_ROOT"' EXIT

mkdir -p "$STAGING_APP/Contents/MacOS" "$STAGING_APP/Contents/Resources"
cp "$BUILD_BINARY" "$STAGING_APP/Contents/MacOS/$APP_NAME"
chmod +x "$STAGING_APP/Contents/MacOS/$APP_NAME"

cat > "$STAGING_APP/Contents/Info.plist" <<PLIST
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

plutil -lint "$STAGING_APP/Contents/Info.plist" >/dev/null

if command -v xattr >/dev/null 2>&1; then
    xattr -cr "$STAGING_APP" 2>/dev/null || true
fi

if command -v codesign >/dev/null 2>&1; then
    if [[ -n "${CODESIGN_IDENTITY:-}" ]]; then
        codesign --force --deep --sign "$CODESIGN_IDENTITY" --identifier "$BUNDLE_ID" --entitlements "$ENTITLEMENTS" "$STAGING_APP"
    else
        # Ad-hoc local builds cannot carry CloudKit entitlements without a team.
        codesign --force --deep --sign - --identifier "$BUNDLE_ID" "$STAGING_APP"
    fi
    codesign --verify --deep --strict "$STAGING_APP"
fi

rm -rf "$APP_BUNDLE"
mv "$STAGING_APP" "$APP_BUNDLE"

echo "$APP_BUNDLE"

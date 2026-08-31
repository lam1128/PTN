#!/bin/zsh

set -euo pipefail
unsetopt BG_NICE

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_PATH="$ROOT_DIR/dist/PTNHypercubeWidget.app"
EXECUTABLE="$APP_PATH/Contents/MacOS/PTNHypercubeWidget"

pkill -x PTNHypercubeWidget >/dev/null 2>&1 || true
"$ROOT_DIR/script/assemble_app.sh" debug "$APP_PATH" >/dev/null

[[ -x "$EXECUTABLE" ]] || {
    echo "构建失败：App 缺少可执行文件 $EXECUTABLE" >&2
    exit 3
}

codesign --verify --deep --strict "$APP_PATH"

# Register only the completed bundle. Unregistering first can leave Launch Services
# pointing at an incomplete app and produce kLSNoExecutableErr.
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
if [[ -x "$LSREGISTER" ]]; then
    "$LSREGISTER" -f "$APP_PATH" >/dev/null 2>&1 || true
fi

if ! /usr/bin/open "$APP_PATH"; then
    "$EXECUTABLE" >/dev/null 2>&1 &
fi

echo "Built standalone app at: $APP_PATH"

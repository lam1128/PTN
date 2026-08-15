#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_PATH="$ROOT_DIR/dist/PTNHypercubeWidget.app"

pkill -x PTNHypercubeWidget >/dev/null 2>&1 || true
"$ROOT_DIR/script/assemble_app.sh" release "$APP_PATH"
/usr/bin/open -n "$APP_PATH"

echo "已生成并打开: $APP_PATH"

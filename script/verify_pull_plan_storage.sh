#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VERIFY_BINARY="$(mktemp "${TMPDIR:-/tmp}/ptn-pull-plan-storage.XXXXXX")"
trap 'rm -f "$VERIFY_BINARY"' EXIT

swiftc \
    "$ROOT_DIR/PTNHypercubeWidget/Models/RewardModels.swift" \
    "$ROOT_DIR/PTNHypercubeWidget/RewardEngine/RewardSchedule.swift" \
    "$ROOT_DIR/PTNHypercubeWidget/RewardEngine/RewardEngine.swift" \
    "$ROOT_DIR/PTNHypercubeWidget/RewardEngine/PullPlanRules.swift" \
    "$ROOT_DIR/PTNHypercubeWidget/Storage/S1NSyncSupport.swift" \
    "$ROOT_DIR/PTNHypercubeWidget/Storage/AppStateStore.swift" \
    "$ROOT_DIR/PTNHypercubeWidget/Storage/AppStateStore+Decoding.swift" \
    "$ROOT_DIR/script/verify_pull_plan_storage.swift" \
    -o "$VERIFY_BINARY"

"$VERIFY_BINARY"

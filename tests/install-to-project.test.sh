#!/usr/bin/env bash
# Tests that install-to-project.sh --force preserves a project's kf.json override.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=tests/lib.sh
source "$REPO_ROOT/tests/lib.sh"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo "install-to-project.sh"

TARGET="$WORK/target"
mkdir -p "$TARGET/.claude"
git -C "$TARGET" init -q
git -C "$TARGET" checkout -q -b setup/tooling
CONFIG='{"beads": {"remotePush": false}}'
echo "$CONFIG" > "$TARGET/.claude/kf.json"

OUT="$(bash "$REPO_ROOT/scripts/install-to-project.sh" "$TARGET" --force 2>&1)"

assert_eq "--force leaves kf.json untouched" "$CONFIG" "$(cat "$TARGET/.claude/kf.json")"
assert_contains "--force reports the preserved override" "Preserved .claude/kf.json" "$OUT"
assert_eq "install still copies rules" true "$([[ -f "$TARGET/.claude/rules/session-close.md" ]] && echo true || echo false)"

finish

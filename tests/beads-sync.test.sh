#!/usr/bin/env bash
# Tests for plugins/kf/skills/session-close/beads-sync.sh against a real bd,
# in throwaway repos. A pass-through bd wrapper records every invocation so
# tests can prove `bd dolt push` never ran.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=tests/lib.sh
source "$REPO_ROOT/tests/lib.sh"

SCRIPT="$REPO_ROOT/plugins/kf/skills/session-close/beads-sync.sh"
REAL_BD="$(command -v bd)" || { echo "bd not installed; skipping"; exit 0; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

mkdir -p "$WORK/bin"
cat > "$WORK/bin/bd" <<EOF
#!/usr/bin/env bash
echo "\$*" >> "\$BD_CALL_LOG"
exec "$REAL_BD" "\$@"
EOF
chmod +x "$WORK/bin/bd"

# new_project NAME -> creates a git repo with an initialised beads db, cds into it
new_project() {
  local dir="$WORK/$1"
  mkdir -p "$dir"
  cd "$dir"
  git init -q
  "$REAL_BD" init --prefix t -q </dev/null >/dev/null 2>&1
  : > "$dir/calls.log"
}

opt_out() {
  mkdir -p .claude
  echo '{"beads": {"remotePush": false}}' > .claude/kf.json
}

# run_sync -> sets OUT and STATUS
run_sync() {
  set +e
  OUT="$(BD_CALL_LOG="$PWD/calls.log" PATH="$WORK/bin:$PATH" "$SCRIPT" 2>&1)"
  STATUS=$?
  set -e
  CALLS="$(cat calls.log)"
}

echo "beads-sync.sh"

# --- default: no kf.json, push happens ---------------------------------------
new_project default
"$REAL_BD" dolt remote add origin "file://$WORK/default-remote" >/dev/null
run_sync
assert_eq "no config: exits 0" 0 "$STATUS"
assert_contains "no config: runs bd dolt push" "dolt push" "$CALLS"
assert_eq "no config: remote received data" true "$([[ -n "$(ls -A "$WORK/default-remote" 2>/dev/null)" ]] && echo true || echo false)"

# --- opt-out, local backup, no remotes: backup only ---------------------------
new_project local-ok
opt_out
"$REAL_BD" backup init "$WORK/local-ok-backup" >/dev/null
run_sync
assert_eq "opt-out: exits 0" 0 "$STATUS"
assert_not_contains "opt-out: never runs bd dolt push" "dolt push" "$CALLS"
assert_contains "opt-out: runs bd backup sync" "backup sync" "$CALLS"
assert_contains "opt-out: says push was skipped" "skipped bd dolt push" "$OUT"

# --- opt-out, but a Dolt remote points off-machine: refuse --------------------
new_project github-remote
opt_out
"$REAL_BD" backup init "$WORK/github-remote-backup" >/dev/null
"$REAL_BD" dolt remote add origin "git+https://github.com/example/private" >/dev/null
run_sync
assert_eq "remote present: exits non-zero" 1 "$STATUS"
assert_not_contains "remote present: never runs bd dolt push" "dolt push" "$CALLS"
assert_not_contains "remote present: does not back up either" "backup sync" "$CALLS"
assert_contains "remote present: names the remote" "github.com/example/private" "$OUT"

# --- opt-out, backup destination is off-machine (DoltHub): refuse -------------
new_project dolthub-backup
opt_out
"$REAL_BD" backup init "https://doltremoteapi.dolthub.com/example/private" >/dev/null
run_sync
assert_eq "remote backup: exits non-zero" 1 "$STATUS"
assert_not_contains "remote backup: never syncs to it" "backup sync" "$CALLS"
assert_contains "remote backup: names the destination" "doltremoteapi.dolthub.com" "$OUT"

# --- opt-out, no backup configured: refuse with guidance ----------------------
# (bare `bd backup sync` prints help and exits 0 here, which would look like success)
new_project no-backup
opt_out
run_sync
assert_eq "no backup: exits non-zero" 1 "$STATUS"
assert_contains "no backup: says how to configure one" "bd backup init" "$OUT"

# --- malformed kf.json: fail closed -------------------------------------------
new_project malformed
mkdir -p .claude
echo '{"beads": {"remotePush": fal' > .claude/kf.json
"$REAL_BD" dolt remote add origin "file://$WORK/malformed-remote" >/dev/null
run_sync
assert_eq "malformed config: exits non-zero" 1 "$STATUS"
assert_not_contains "malformed config: never runs bd dolt push" "dolt push" "$CALLS"

# --- run from a subdirectory: still finds the config --------------------------
new_project subdir
opt_out
"$REAL_BD" backup init "$WORK/subdir-backup" >/dev/null
mkdir -p src/deep && : > calls.log
( cd src/deep && set +e
  OUT="$(BD_CALL_LOG="$WORK/subdir/calls.log" PATH="$WORK/bin:$PATH" "$SCRIPT" 2>&1)"; echo "$?" > "$WORK/subdir/status" )
assert_eq "subdirectory: exits 0" 0 "$(cat "$WORK/subdir/status")"
assert_not_contains "subdirectory: never runs bd dolt push" "dolt push" "$(cat calls.log)"

finish

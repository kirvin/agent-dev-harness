#!/usr/bin/env bash
# Tests for plugins/kf/skills/session-close/beads-sync.sh against a real bd,
# in throwaway repos. A pass-through bd wrapper records every invocation so
# tests can prove `bd dolt push` never ran.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=tests/lib.sh
source "$REPO_ROOT/tests/lib.sh"

SCRIPT="$REPO_ROOT/plugins/kf/skills/session-close/beads-sync.sh"
REAL_BD="$(command -v bd)" || { echo "FAIL bd is not installed; these tests need a real bd"; exit 1; }

WORK="$(mktemp -d)"
WORK="$(cd "$WORK" && pwd -P)"
trap 'rm -rf "$WORK"' EXIT

mkdir -p "$WORK/bin"
cat > "$WORK/bin/bd" <<EOF
#!/usr/bin/env bash
echo "\$*" >> "\$BD_CALL_LOG"
if [[ -n "\${BD_FAIL_CONFIG_GET:-}" && "\$*" == *"config get"*"\$BD_FAIL_CONFIG_GET"* ]]; then echo "simulated failure" >&2; exit 1; fi
exec "$REAL_BD" "\$@"
EOF
chmod +x "$WORK/bin/bd"

# A PATH with the wrapper and the basics but no jq.
mkdir -p "$WORK/nojq"
for tool in bash env git dirname; do ln -s "$(command -v "$tool")" "$WORK/nojq/$tool"; done
ln -s "$WORK/bin/bd" "$WORK/nojq/bd"

# new_project NAME [BEADS_SUBDIR] -> git repo with a beads db; cds into the beads dir
new_project() {
  local dir="$WORK/$1"
  mkdir -p "$dir/${2:-.}"
  git -C "$dir" init -q
  cd "$dir/${2:-.}"
  "$REAL_BD" init --prefix t -q </dev/null >/dev/null 2>"$WORK/init.err" || { cat "$WORK/init.err"; exit 1; }
  : > calls.log
}

write_config() { mkdir -p .claude; echo "$1" > .claude/kf.json; }

# opt_out -> the full supported opt-out: config, bd's no-push, a local backup outside the repo
opt_out() {
  write_config '{"beads": {"remotePush": false}}'
  "$REAL_BD" config set no-push true >/dev/null
  "$REAL_BD" backup init "$WORK/backups/$(basename "$PWD")-$RANDOM" >/dev/null
}

# run_sync [PATH] [HOME] -> sets OUT, STATUS, CALLS
run_sync() {
  set +e
  OUT="$(BD_CALL_LOG="$PWD/calls.log" PATH="${1:-$WORK/bin:$PATH}" HOME="${2:-$HOME}" "$SCRIPT" 2>&1)"
  STATUS=$?
  set -e
  CALLS="$(cat calls.log)"
}

# refused NAME NEEDLE -> exit 1, message contains NEEDLE, nothing pushed or synced
refused() {
  assert_eq "$1: exits 1" 1 "$STATUS"
  assert_contains "$1: explains why" "$2" "$OUT"
  assert_not_contains "$1: never runs bd dolt push" "dolt push" "$CALLS"
  assert_not_contains "$1: never runs bd backup sync" "backup sync" "$CALLS"
}

has_files() { [[ -n "$(ls -A "$1" 2>/dev/null)" ]] && echo true || echo false; }

echo "beads-sync.sh"

# --- push path ----------------------------------------------------------------
new_project default
"$REAL_BD" dolt remote add origin "file://$WORK/default-remote" >/dev/null
run_sync
assert_eq "no config: exits 0" 0 "$STATUS"
assert_contains "no config: runs bd dolt push" "dolt push" "$CALLS"
assert_eq "no config: remote received data" true "$(has_files "$WORK/default-remote")"

new_project explicit-true
write_config '{"beads": {"remotePush": true}}'
"$REAL_BD" dolt remote add origin "file://$WORK/explicit-true-remote" >/dev/null
run_sync
assert_eq "remotePush true: exits 0" 0 "$STATUS"
assert_contains "remotePush true: runs bd dolt push" "dolt push" "$CALLS"

new_project empty-config
write_config '{}'
"$REAL_BD" dolt remote add origin "file://$WORK/empty-config-remote" >/dev/null
run_sync
assert_eq "empty config: pushes" 0 "$STATUS"
assert_contains "empty config: runs bd dolt push" "dolt push" "$CALLS"

# --- supported opt-out ----------------------------------------------------------
new_project local-ok
opt_out
run_sync
assert_eq "opt-out: exits 0" 0 "$STATUS"
assert_not_contains "opt-out: never runs bd dolt push" "dolt push" "$CALLS"
assert_contains "opt-out: runs bd backup sync" "backup sync" "$CALLS"
assert_contains "opt-out: says push was skipped" "skipped bd dolt push" "$OUT"

new_project local-remote
opt_out
"$REAL_BD" dolt remote add origin "file://$WORK/local-remote-remote" >/dev/null
run_sync
assert_eq "opt-out with a local file remote: exits 0" 0 "$STATUS"
assert_not_contains "opt-out with a local file remote: never pushes" "dolt push" "$CALLS"
assert_eq "opt-out with a local file remote: remote untouched" false "$(has_files "$WORK/local-remote-remote")"

new_project nested sub/app
opt_out
run_sync
assert_eq "beads below the git root: opt-out honoured" 0 "$STATUS"
assert_not_contains "beads below the git root: never pushes" "dolt push" "$CALLS"

new_project subdir
opt_out
mkdir -p src/deep
( cd src/deep && set +e
  BD_CALL_LOG="$WORK/subdir/calls.log" PATH="$WORK/bin:$PATH" "$SCRIPT" >/dev/null 2>&1; echo "$?" > "$WORK/subdir/status" )
CALLS="$(cat calls.log)"
assert_eq "run from a subdirectory: exits 0" 0 "$(cat "$WORK/subdir/status")"
assert_not_contains "run from a subdirectory: never pushes" "dolt push" "$CALLS"
assert_contains "run from a subdirectory: backs up" "backup sync" "$CALLS"

# --- config that must fail closed ----------------------------------------------
new_project malformed
write_config '{"beads": {"remotePush": fal'
run_sync
refused "malformed JSON" "kf.json"

new_project string-false
write_config '{"beads": {"remotePush": "false"}}'
run_sync
refused 'remotePush "false" (string)' "must be true or false"

new_project typo
write_config '{"beads": {"remote_push": false}}'
run_sync
refused "misspelled key under beads" "remote_push"

new_project top-level-typo
write_config '{"bead": {"remotePush": false}}'
run_sync
refused "misspelled top-level key" "bead"

new_project no-jq
opt_out
run_sync "$WORK/nojq"
refused "jq missing" "jq"

# --- opt-out with an unsafe environment -----------------------------------------
new_project no-push-unset
opt_out
"$REAL_BD" config set no-push false >/dev/null
run_sync
refused "bd no-push not set" "bd config set no-push true"

new_project auto-push
opt_out
"$REAL_BD" config set dolt.auto-push true >/dev/null
run_sync
refused "dolt.auto-push on" "dolt.auto-push"

new_project auto-push-numeric
opt_out
"$REAL_BD" config set dolt.auto-push 1 >/dev/null
run_sync
refused "dolt.auto-push set to 1" "dolt.auto-push"

new_project config-read-fails
opt_out
set +e
OUT="$(BD_FAIL_CONFIG_GET=dolt.auto-push BD_CALL_LOG="$PWD/calls.log" PATH="$WORK/bin:$PATH" "$SCRIPT" 2>&1)"; STATUS=$?
set -e
CALLS="$(cat calls.log)"
refused "bd config read fails" "could not read bd config"

new_project git-add-export
opt_out
"$REAL_BD" config set export.auto true >/dev/null
"$REAL_BD" config set export.git-add true >/dev/null
run_sync
refused "export to git on" "export."

new_project github-remote
opt_out
"$REAL_BD" dolt remote add origin "git+https://github.com/example/private" >/dev/null
run_sync
refused "off-machine Dolt remote" "github.com/example/private"

new_project dolthub-backup
opt_out
"$REAL_BD" backup remove >/dev/null
"$REAL_BD" backup init "https://doltremoteapi.dolthub.com/example/private" >/dev/null
run_sync
refused "off-machine backup" "doltremoteapi.dolthub.com"

new_project backup-in-repo
opt_out
"$REAL_BD" backup remove >/dev/null
"$REAL_BD" backup init "$PWD/backups/beads" >/dev/null
run_sync
refused "backup inside the repo" "inside the repository"

new_project remote-in-repo
opt_out
"$REAL_BD" dolt remote add origin "file://$PWD/dolt-remote" >/dev/null
run_sync
refused "file remote inside the repo" "inside the repository"

new_project case-repo
if [[ "$WORK/case-repo" -ef "$WORK/CASE-REPO" ]]; then
  opt_out
  "$REAL_BD" backup remove >/dev/null
  "$REAL_BD" backup init "$WORK/CASE-REPO/bk" >/dev/null
  run_sync
  refused "backup inside the repo, path in different case" "inside the repository"
else
  echo "  skip backup path in different case (case-sensitive filesystem)"
fi

new_project backup-in-documents
opt_out
"$REAL_BD" backup remove >/dev/null
mkdir -p "$WORK/home/Documents"
"$REAL_BD" backup init "$WORK/home/Documents/beads-backup" >/dev/null
run_sync "$WORK/bin:$PATH" "$WORK/home"
refused "backup in ~/Documents (iCloud Desktop & Documents)" "cloud-synced"

new_project backup-in-dropbox
opt_out
"$REAL_BD" backup remove >/dev/null
mkdir -p "$WORK/home/Dropbox"
"$REAL_BD" backup init "$WORK/home/Dropbox/beads-backup" >/dev/null
run_sync "$WORK/bin:$PATH" "$WORK/home"
refused "backup in a cloud-synced folder" "cloud-synced"

if [[ "$WORK/home/Dropbox" -ef "$WORK/home/dropbox" ]]; then
  new_project backup-in-dropbox-case
  opt_out
  "$REAL_BD" backup remove >/dev/null
  "$REAL_BD" backup init "$WORK/home/dropbox/beads-backup-2" >/dev/null
  run_sync "$WORK/bin:$PATH" "$WORK/home"
  refused "backup in a cloud-synced folder, path in different case" "cloud-synced"
else
  echo "  skip cloud folder path in different case (case-sensitive filesystem)"
fi

# (bare `bd backup sync` prints help and exits 0 here, which would look like success)
new_project no-backup
write_config '{"beads": {"remotePush": false}}'
"$REAL_BD" config set no-push true >/dev/null
run_sync
refused "no backup configured" "bd backup init"

finish

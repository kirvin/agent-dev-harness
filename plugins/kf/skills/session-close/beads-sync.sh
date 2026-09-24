#!/usr/bin/env bash
# beads-sync.sh — the beads half of session-close Step 3.
#
# Default: `bd dolt push`.
#
# Opt-out: a project whose beads data must never leave the machine commits
#   .claude/kf.json  ->  {"beads": {"remotePush": false}}
# next to its .beads/ directory (or at the git root), and sets bd's own kill
# switch: `bd config set no-push true`. The script then never pushes. It checks,
# read-only, every path by which beads data could leave, refuses if any is
# open, and otherwise runs `bd backup sync` to a local path. Anything it
# cannot read or does not recognise is a refusal, never a push.
#
# Why not just unset sync.remote: bd falls back to the git origin, and the
# Dolt database keeps its own `origin` remote. Only the remote list is truth.

set -euo pipefail

die() { echo "beads-sync: $*" >&2; exit 1; }

command -v bd >/dev/null || die "bd is not installed."

# Anchor on bd's own view of where the database is, not the git root: in a
# nested layout they differ, and a missed config would mean a push.
GIT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
BEADS_DIR=""
if command -v jq >/dev/null; then
  BEADS_DIR="$(bd where --json 2>/dev/null | jq -r '.path // empty' 2>/dev/null || true)"
fi
BEADS_ROOT="${BEADS_DIR:+$(dirname "$BEADS_DIR")}"

# Also walk up for .beads/ ourselves, so a missing jq cannot hide a config.
WALKED_ROOT=""
dir="$PWD"
while [[ "$dir" != "/" ]]; do
  if [[ -d "$dir/.beads" ]]; then WALKED_ROOT="$dir"; break; fi
  dir="$(dirname "$dir")"
done

CONFIGS=()
for root in "$BEADS_ROOT" "$WALKED_ROOT" "$GIT_ROOT" "$PWD"; do
  [[ -n "$root" && -f "$root/.claude/kf.json" ]] || continue
  [[ " ${CONFIGS[*]-} " == *" $root/.claude/kf.json "* ]] || CONFIGS+=("$root/.claude/kf.json")
done

if [[ ${#CONFIGS[@]} -eq 0 ]]; then
  exec bd dolt push
fi

command -v jq >/dev/null || die "${CONFIGS[0]} exists but jq is not installed; refusing to push. Install jq."
[[ -n "$BEADS_DIR" ]] || die "could not locate the beads database (bd where); refusing to continue."

# Prints "push" or "local"; any other shape is an error.
read_mode() {
  jq -r '
    if type != "object" then error("top level must be a JSON object")
    elif .beads == null then "push"
    elif (.beads | type) != "object" then error("\"beads\" must be an object")
    elif ((.beads | keys) - ["remotePush"]) != [] then
      error("unknown key(s) under \"beads\": \((.beads | keys) - ["remotePush"] | join(", ")) (did you mean remotePush?)")
    elif .beads.remotePush == null or .beads.remotePush == true then "push"
    elif .beads.remotePush == false then "local"
    else error("beads.remotePush must be true or false, got \(.beads.remotePush | tojson)")
    end' "$1"
}

MODE="push"
for config in "${CONFIGS[@]}"; do
  mode="$(read_mode "$config" 2>&1)" || die "$config is not usable; refusing to push.
$mode"
  [[ "$mode" == "local" ]] && MODE="local"
done

if [[ "$MODE" == "push" ]]; then
  exec bd dolt push
fi

# ---------------------------------------------------------------------------
# Opt-out: read-only checks, then a local backup.
# ---------------------------------------------------------------------------

PROBLEMS=()
problem() { PROBLEMS+=("$1"); }

bd_config() {
  bd config get --json "$1" | jq -r '.value // ""' \
    || die "could not read bd config $1; refusing to continue."
}

# Resolve a path whose tail may not exist yet, following symlinks in the part that does.
resolve_path() {
  local path="$1" tail=""
  while [[ ! -d "$path" && "$path" != "/" ]]; do
    tail="/$(basename "$path")$tail"
    path="$(dirname "$path")"
  done
  echo "$(cd "$path" && pwd -P)$tail"
}

is_under() { [[ "$1/" == "$2/"* ]]; }

[[ "$(bd_config no-push)" == "true" ]] \
  || problem "bd's own push kill switch is off. Run: bd config set no-push true (and commit .beads/config.yaml)"
[[ "$(bd_config dolt.auto-push)" != "true" ]] \
  || problem "dolt.auto-push is on, so writes push in the background. Run: bd config set dolt.auto-push false"
for key in export.auto export.git-add events-export; do
  [[ "$(bd_config "$key")" != "true" ]] \
    || problem "$key is on; it writes issue data into the repo where git push can publish it. Run: bd config set $key false"
done

REMOTES_JSON="$(bd dolt remote list --json)" || die "could not list Dolt remotes; refusing to continue."
REMOTES="$(jq -r '.[] | "\(.name)\t\(.url)"' <<<"$REMOTES_JSON")" \
  || die "unexpected output from bd dolt remote list; refusing to continue."
while IFS=$'\t' read -r name url; do
  [[ -n "$name" ]] || continue
  [[ "$url" == file://* || "$url" == /* ]] \
    || problem "Dolt remote '$name' points off-machine: $url. Remove it: bd dolt remote remove $name"
done <<<"$REMOTES"

BACKUP_JSON="$(bd backup status --json)" || die "could not read backup status; refusing to continue."
BACKUP_URL="$(jq -r 'if .dolt.configured then .dolt.backup_url else "" end' <<<"$BACKUP_JSON")" \
  || die "unexpected output from bd backup status; refusing to continue."

if [[ -z "$BACKUP_URL" ]]; then
  problem "no local backup is configured. Run: bd backup init <local path outside the repo>"
elif [[ "$BACKUP_URL" != file://* && "$BACKUP_URL" != /* ]]; then
  problem "the backup destination is off-machine: $BACKUP_URL. Run: bd backup remove && bd backup init <local path>"
else
  BACKUP_PATH="$(resolve_path "${BACKUP_URL#file://}")"
  for root in "$BEADS_ROOT" "$GIT_ROOT"; do
    [[ -n "$root" ]] || continue
    if is_under "$BACKUP_PATH" "$(resolve_path "$root")"; then
      problem "the backup at $BACKUP_PATH is inside the repository, where git push can publish it. Move it outside the repo."
      break
    fi
  done
  HOME_REAL="$(resolve_path "$HOME")"
  for synced in Dropbox "Google Drive" OneDrive iCloudDrive Library/CloudStorage "Library/Mobile Documents"; do
    if is_under "$BACKUP_PATH" "$HOME_REAL/$synced"; then
      problem "the backup at $BACKUP_PATH is in a cloud-synced folder ($synced). Use a path that is not synced."
      break
    fi
  done
fi

if [[ ${#PROBLEMS[@]} -gt 0 ]]; then
  {
    echo "beads-sync: beads.remotePush is false, but beads data could still leave this machine."
    printf '  - %s\n' "${PROBLEMS[@]}"
    echo "Nothing was pushed or synced. Fix the above, then re-run."
  } >&2
  exit 1
fi

bd backup sync
echo "beads-sync: skipped bd dolt push (beads.remotePush is false); backed up to $BACKUP_PATH"

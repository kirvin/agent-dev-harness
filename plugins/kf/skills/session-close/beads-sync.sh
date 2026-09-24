#!/usr/bin/env bash
# beads-sync.sh — the beads half of session-close Step 3.
#
# Default: `bd dolt push`.
#
# Opt-out: a project whose beads data must never leave the machine commits
#   .claude/kf.json  ->  {"beads": {"remotePush": false}}
# The script then never pushes. Instead it verifies, read-only, that no Dolt
# remote and no backup destination points off-machine, and runs
# `bd backup sync` to a local path. Any doubt (unreadable config, off-machine
# URL, no backup configured) exits 1 without touching the network.
#
# Why not just unset sync.remote: bd falls back to the git origin, and the
# Dolt database keeps its own `origin` remote. Only the remote list is truth.

set -euo pipefail

die() { echo "beads-sync: $*" >&2; exit 1; }

PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || PROJECT_ROOT="$PWD"
CONFIG="$PROJECT_ROOT/.claude/kf.json"

if [[ ! -f "$CONFIG" ]]; then
  exec bd dolt push
fi

command -v jq >/dev/null || die "$CONFIG exists but jq is not installed; refusing to push. Install jq."

REMOTE_PUSH="$(jq -r 'if .beads.remotePush == false then "false" else "true" end' "$CONFIG" 2>/dev/null)" \
  || die "$CONFIG is not valid JSON; refusing to push. Fix the file."

if [[ "$REMOTE_PUSH" == "true" ]]; then
  exec bd dolt push
fi

is_local_url() {
  [[ "$1" == file://* || "$1" == /* ]]
}

REMOTES_JSON="$(bd dolt remote list --json)" || die "could not list Dolt remotes; refusing to continue."
OFFENDING="$(jq -r '.[] | "\(.name) \(.url)"' <<<"$REMOTES_JSON" | while read -r name url; do
  is_local_url "$url" || echo "  $name -> $url"
done)"
if [[ -n "$OFFENDING" ]]; then
  die "beads.remotePush is false, but these Dolt remotes point off-machine:
$OFFENDING
Remove them (bd dolt remote remove <name>) before closing the session. Nothing was pushed."
fi

BACKUP_JSON="$(bd backup status --json)" || die "could not read backup status; refusing to continue."
BACKUP_URL="$(jq -r 'if .dolt.configured then .dolt.backup_url else "" end' <<<"$BACKUP_JSON")"
if [[ -z "$BACKUP_URL" ]]; then
  die "beads.remotePush is false and no local backup is configured.
Configure one: bd backup init <local path outside the repo>"
fi
if ! is_local_url "$BACKUP_URL"; then
  die "beads.remotePush is false, but the backup destination is off-machine: $BACKUP_URL
Point it at a local path: bd backup remove && bd backup init <local path>. Nothing was synced."
fi

bd backup sync
echo "beads-sync: skipped bd dolt push (beads.remotePush is false in .claude/kf.json); backed up to $BACKUP_URL"

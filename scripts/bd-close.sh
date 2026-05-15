#!/usr/bin/env bash
# bd-close.sh — Close a beads issue and its linked GitHub issue.
#
# Usage (from project root or via make):
#   ./scripts/bd-close.sh <issue-id> [<issue-id>...] [--reason="explanation"]
#   make bd-close id=<issue-id> [reason="..."]
#
# If the beads issue description contains a GitHub issue URL
# (https://github.com/.../issues/<n>), that GitHub issue is also closed
# with a comment. Otherwise behaves exactly like `bd close`.

set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
ok()   { echo -e "${GREEN}✓${NC}  $*"; }
warn() { echo -e "${YELLOW}!${NC}  $*"; }
fail() { echo -e "${RED}✗${NC}  $*" >&2; exit 1; }

# ---------------------------------------------------------------------------
# Parse args
# ---------------------------------------------------------------------------

REASON=""
ISSUE_IDS=()

for arg in "$@"; do
  case "$arg" in
    --reason=*) REASON="${arg#--reason=}" ;;
    --*)        fail "Unknown option: $arg" ;;
    *)          ISSUE_IDS+=("$arg") ;;
  esac
done

if [[ ${#ISSUE_IDS[@]} -eq 0 ]]; then
  echo "Usage: $0 <issue-id> [<issue-id>...] [--reason=\"explanation\"]" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Check gh auth lazily (once, only if we find a linked GitHub issue)
# ---------------------------------------------------------------------------

GH_STATUS=""  # "ok", "skip", or ""

check_gh_auth() {
  [[ -n "$GH_STATUS" ]] && return
  if ! command -v gh &>/dev/null; then
    warn "gh CLI not found — GitHub issue auto-close disabled"
    GH_STATUS="skip"
    return
  fi
  if ! gh auth status &>/dev/null 2>&1; then
    warn "gh not authenticated — GitHub issue auto-close disabled"
    GH_STATUS="skip"
    return
  fi
  GH_STATUS="ok"
}

# ---------------------------------------------------------------------------
# Close a single beads issue (and its GitHub counterpart if linked)
# ---------------------------------------------------------------------------

close_one() {
  local id="$1"

  # Look for a GitHub issue URL in the beads issue description
  local github_url
  github_url=$(bd show "$id" 2>/dev/null \
    | grep -oE 'https://github\.com/[^/]+/[^/]+/issues/[0-9]+' \
    | head -1 || true)

  if [[ -n "$github_url" ]]; then
    check_gh_auth
    if [[ "$GH_STATUS" == "ok" ]]; then
      local repo issue_num comment
      repo=$(echo "$github_url" | sed 's|https://github.com/||; s|/issues/[0-9]*$||')
      issue_num=$(echo "$github_url" | grep -oE '[0-9]+$')
      comment="Resolved via beads issue ${id}."
      [[ -n "$REASON" ]] && comment="${comment} ${REASON}"

      if gh issue close "$issue_num" --repo "$repo" --comment "$comment" 2>/dev/null; then
        ok "Closed GitHub #${issue_num} (${repo})"
      else
        warn "Could not close GitHub #${issue_num} — close manually: ${github_url}"
      fi
    fi
  fi

  # Always close the beads issue
  if [[ -n "$REASON" ]]; then
    bd close "$id" --reason="$REASON"
  else
    bd close "$id"
  fi
  ok "Closed beads issue: ${id}"
}

# ---------------------------------------------------------------------------
# Main — process all IDs
# ---------------------------------------------------------------------------

for id in "${ISSUE_IDS[@]}"; do
  close_one "$id"
done

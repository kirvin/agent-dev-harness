#!/usr/bin/env bash
# bd-close — close a beads issue and auto-close any linked GitHub issue
#
# Usage: ./scripts/bd-close.sh <id> [<id2> ...] [--reason="..."]
#   or:  make bd-close id=<id> [reason="..."]
#
# If the beads issue description contains a GitHub issue URL
# (https://github.com/*/issues/<n>), the corresponding GitHub issue is closed
# with a comment referencing the beads task.

set -euo pipefail

if [[ $# -eq 0 ]]; then
  echo "Usage: $0 <beads-id> [<beads-id2> ...] [--reason=\"...\"]" >&2
  exit 1
fi

# Split args into IDs and flags (--reason etc.)
ids=()
flags=()
for arg in "$@"; do
  if [[ "$arg" == --* ]]; then
    flags+=("$arg")
  else
    ids+=("$arg")
  fi
done

# Resolve GitHub issue URLs before closing (bd show only works on open issues).
# Parallel arrays: linked_ids / linked_urls share the same index.
linked_ids=()
linked_urls=()
for id in "${ids[@]}"; do
  url=$(bd show "$id" 2>/dev/null \
        | grep -oE 'https://github\.com/[^/]+/[^/]+/issues/[0-9]+' \
        | head -1 || true)
  if [[ -n "$url" ]]; then
    linked_ids+=("$id")
    linked_urls+=("$url")
  fi
done

# Close the beads issue(s)
bd close "${ids[@]}" "${flags[@]}"

# Close any linked GitHub issues
for i in "${!linked_ids[@]}"; do
  id="${linked_ids[$i]}"
  url="${linked_urls[$i]}"
  echo "Closing GitHub issue: $url"
  if gh issue close "$url" --comment "Fixed. Tracked in beads task \`$id\`."; then
    echo "  ✓ Closed $url"
  else
    echo "  ✗ Could not close $url — check \`gh auth status\`" >&2
  fi
done

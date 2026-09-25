#!/usr/bin/env bash
# check-conventional-commits.sh — fail if a PR title or any non-merge commit
# subject in BASE..HEAD is not a Conventional Commit.
#
# Usage: PR_TITLE="<title>" scripts/check-conventional-commits.sh BASE HEAD
#
# auto (the release tool) reads each commit's type to pick the version bump:
# fix -> patch, feat -> minor, ! or BREAKING CHANGE -> major, other types -> no
# release. A subject without a type contributes nothing, so a "Fix bug" commit
# would silently ship no release. The title is checked too, for squash merges.

set -euo pipefail

TYPES="feat|fix|perf|refactor|docs|style|test|build|ci|chore|revert"
PATTERN="^($TYPES)(\([^()]+\))?!?: [^ ].*"

[[ $# -eq 2 ]] || { echo "usage: PR_TITLE=... $0 BASE HEAD" >&2; exit 2; }
BASE="$1"
HEAD="$2"

bad=()
is_conventional() { [[ "$1" =~ $PATTERN || "$1" =~ ^Revert\ \" ]]; }

if [[ -n "${PR_TITLE:-}" ]] && ! is_conventional "$PR_TITLE"; then
  bad+=("PR title: $PR_TITLE")
fi

# One line per commit, "<sha> <subject>", so an empty subject is still seen.
while read -r sha subject; do
  [[ -n "$sha" ]] || continue
  if [[ -z "$subject" ]]; then
    bad+=("commit ${sha:0:7}: (empty message)")
  elif ! is_conventional "$subject"; then
    bad+=("commit: $subject")
  fi
done < <(git log --no-merges --format='%H %s' "$BASE..$HEAD")

if [[ ${#bad[@]} -gt 0 ]]; then
  echo "Not Conventional Commits (type(scope)!: description, type one of ${TYPES//|/, }):" >&2
  printf '  %s\n' "${bad[@]}" >&2
  echo "Reword with: git rebase -i $BASE (reword), then force-push the branch." >&2
  exit 1
fi
echo "All commit subjects and the PR title are Conventional Commits."

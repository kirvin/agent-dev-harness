#!/usr/bin/env bash
# Tests for scripts/check-conventional-commits.sh in throwaway git repos.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=tests/lib.sh
source "$REPO_ROOT/tests/lib.sh"

SCRIPT="$REPO_ROOT/scripts/check-conventional-commits.sh"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# new_repo -> fresh repo with one base commit; sets BASE; cds into it
new_repo() {
  local dir
  dir="$(mktemp -d "$WORK/repo.XXXX")"
  cd "$dir"
  git init -q
  git config user.name Test
  git config user.email test@example.invalid
  git commit -q --allow-empty -m "chore: base"
  BASE="$(git rev-parse HEAD)"
}

commit() { git commit -q --allow-empty -m "$1"; }

# check TITLE -> sets OUT and STATUS
check() {
  set +e
  OUT="$(PR_TITLE="$1" "$SCRIPT" "$BASE" HEAD 2>&1)"
  STATUS=$?
  set -e
}

echo "check-conventional-commits.sh"

new_repo
commit "feat(install): add a thing"
commit "fix!: change the contract"
commit 'Revert "fix: something"'
check "fix(session-close): keep beads local"
assert_eq "valid title and commits: exits 0" 0 "$STATUS"

new_repo
commit "fix: a thing"
check "Keep beads local"
assert_eq "bad title: exits 1" 1 "$STATUS"
assert_contains "bad title: quotes it" "Keep beads local" "$OUT"

new_repo
commit "fix: a thing"
commit "Update stuff"
check "fix: a thing"
assert_eq "bad commit subject: exits 1" 1 "$STATUS"
assert_contains "bad commit subject: quotes it" "Update stuff" "$OUT"

new_repo
commit "feature: not a real type"
check "fix: ok"
assert_eq "unknown type: exits 1" 1 "$STATUS"

new_repo
commit "fix: "
check "fix: ok"
assert_eq "empty description: exits 1" 1 "$STATUS"

new_repo
git switch -q -c side
commit "fix: on the side"
git switch -q -
git merge -q --no-ff side -m "Merge branch 'side'"
check "fix: merge the side branch"
assert_eq "merge commits are ignored: exits 0" 0 "$STATUS"

new_repo
commit "docs: note"
check ""
assert_eq "no title given: checks commits only" 0 "$STATUS"

finish

#!/usr/bin/env bash
# Rules and skills must not call a kf-shipped skill a "project skill": agents
# then look for it in .claude/skills/, which provisioned projects don't have.
# Matches across line breaks, since prose wraps.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=tests/lib.sh
source "$REPO_ROOT/tests/lib.sh"

echo "skill references"

cd "$REPO_ROOT"
for dir in plugins/kf/skills/*/; do
  name="$(basename "$dir")"
  hits="$(perl -0777 -ne 'while (/`\Q'"$name"'\E`\s+project\s+skill/g) { print "$ARGV\n" }' \
    .claude/rules/*.md plugins/kf/skills/*/SKILL.md AGENTS.md CLAUDE.md | sort -u | tr '\n' ' ')"
  assert_eq "\`$name\` is never called a project skill" "" "$hits"
done

finish

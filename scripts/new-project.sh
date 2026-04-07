#!/usr/bin/env bash
# new-project.sh — scaffold a new private GitHub repo with Claude Code config
# Usage: ./scripts/new-project.sh "My Project Name"

set -euo pipefail

# ---------------------------------------------------------------------------
# Args & slug
# ---------------------------------------------------------------------------

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 \"Project Name\"" >&2
  exit 1
fi

PROJECT_NAME="$1"

# kebab-case: lowercase, collapse non-alphanumeric runs to hyphens, trim edges
SLUG=$(echo "$PROJECT_NAME" \
  | tr '[:upper:]' '[:lower:]' \
  | sed 's/[^a-z0-9]+/-/g; s/^-//; s/-$//')

# Fallback for systems where sed ERE isn't default
SLUG=$(echo "$SLUG" | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')

echo "Project : $PROJECT_NAME"
echo "Slug    : $SLUG"
echo

# ---------------------------------------------------------------------------
# Dependency checks
# ---------------------------------------------------------------------------

for cmd in gh git npx bd dolt; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "Error: '$cmd' is not installed or not on PATH." >&2
    exit 1
  fi
done

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_REPO="$(dirname "$SCRIPT_DIR")"   # parent of scripts/ = claude-config root
WORKSPACES_DIR="$(dirname "$CONFIG_REPO")"  # sibling of claude-config
TARGET_DIR="$WORKSPACES_DIR/$SLUG"

echo "Config source : $CONFIG_REPO"
echo "Target dir    : $TARGET_DIR"
echo

# ---------------------------------------------------------------------------
# 1. Create private GitHub repo
# ---------------------------------------------------------------------------

echo "==> Creating private GitHub repo: $SLUG"
gh repo create "$SLUG" \
  --private \
  --description "$PROJECT_NAME" \
  --confirm 2>/dev/null || \
gh repo create "$SLUG" \
  --private \
  --description "$PROJECT_NAME"

# Resolve full repo name (owner/slug) from gh
GH_REPO=$(gh repo view "$SLUG" --json nameWithOwner -q .nameWithOwner 2>/dev/null \
  || gh repo view "$SLUG" --json nameWithOwner --jq .nameWithOwner)

echo "    Repo: https://github.com/$GH_REPO"
echo

# ---------------------------------------------------------------------------
# 2. Clone locally
# ---------------------------------------------------------------------------

echo "==> Cloning into $TARGET_DIR"
gh repo clone "$GH_REPO" "$TARGET_DIR"
cd "$TARGET_DIR"
echo

# ---------------------------------------------------------------------------
# 3. Copy Claude Code config files
# ---------------------------------------------------------------------------

echo "==> Copying Claude Code config from $CONFIG_REPO"
cp -r "$CONFIG_REPO/.claude" .
cp "$CONFIG_REPO/skills-lock.json" .
cp "$CONFIG_REPO/CLAUDE.md" .
echo

# ---------------------------------------------------------------------------
# 4. Create README with correct project name
# ---------------------------------------------------------------------------

echo "==> Writing README.md"
cat > README.md <<HEREDOC
# $PROJECT_NAME
HEREDOC
echo

# ---------------------------------------------------------------------------
# 5. Customize CLAUDE.md — update placeholder doc links comment
#    (The template already has the right structure; just note it needs editing)
# ---------------------------------------------------------------------------

# No automated edits — user is expected to customize per the README instructions.

# ---------------------------------------------------------------------------
# 6. Install skills
# ---------------------------------------------------------------------------

echo "==> Installing skills (npx skills experimental_install)"
npx skills experimental_install --yes --agent claude-code
echo

# ---------------------------------------------------------------------------
# 7. Initialize Beads
# ---------------------------------------------------------------------------

echo "==> Initializing Beads"
bd init --shared-server
bd hooks install

# bd init creates the local .beads/ config but does NOT create the database
# on the shared Dolt server — that must be done before any bd commands will work.
SHARED_DOLT_DIR="$HOME/.beads/shared-server/dolt"
echo "    Creating Dolt database '$SLUG' in shared server ($SHARED_DOLT_DIR)"
mkdir -p "$SHARED_DOLT_DIR/$SLUG"
(cd "$SHARED_DOLT_DIR/$SLUG" && dolt init)

# Restart the server so it discovers the new database, then apply the schema.
echo "    Restarting shared Dolt server"
bd dolt stop
bd dolt start

echo "    Applying Beads schema"
bd migrate
echo

# ---------------------------------------------------------------------------
# 8. Initial commit
# ---------------------------------------------------------------------------

echo "==> Committing initial config"
git add .claude/ skills-lock.json CLAUDE.md README.md .beads/ 2>/dev/null || true
git add . 2>/dev/null || true
git commit -m "chore: add Claude Code configuration"
git push -u origin main
echo

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------

echo "============================================================"
echo "  Project ready: $TARGET_DIR"
echo "  GitHub:        https://github.com/$GH_REPO"
echo "============================================================"
echo
echo "Next steps:"
echo "  1. cd $TARGET_DIR"
echo "  2. Update CLAUDE.md — fix the doc links for this project"
echo "  3. Remove rules you don't need (.claude/rules/npm.md, etc.)"
echo "  4. Open Claude Code and start building"

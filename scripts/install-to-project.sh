#!/usr/bin/env bash
# install-to-project.sh — Copy the agent-dev-harness toolkit into an existing project.
#
# Usage (from the agent-dev-harness directory):
#   ./scripts/install-to-project.sh TARGET_DIR [--force] [--update] [--dry-run]
#
# TARGET_DIR  Path to the project repo to install into (must be a git repo).
# --dry-run   Print what would be copied without writing anything.
# --force     Overwrite existing files (default: skip existing).
# --update    Refresh harness-managed files in an already-installed project:
#             overwrites whole-file toolkit artifacts (scripts/, .claude/rules/,
#             statusLine.sh, AGENTS.md, Brewfile, .env.example) and re-renders the
#             guarded harness block in CLAUDE.md while preserving user content.
#             Unlike --force, it never clobbers user-owned sections or settings.
#
# After this script completes, switch to the target project and run:
#   cd TARGET_DIR && ./scripts/setup.sh

set -euo pipefail

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
ok()   { echo -e "${GREEN}✓${NC}  $*"; }
warn() { echo -e "${YELLOW}!${NC}  $*"; }
fail() { echo -e "${RED}✗${NC}  $*" >&2; exit 1; }
step() { echo -e "\n${YELLOW}==>${NC} $*"; }

# ---------------------------------------------------------------------------
# Args
# ---------------------------------------------------------------------------

FORCE=false
UPDATE=false
DRY_RUN=false
TARGET_DIR=""

for arg in "$@"; do
  case "$arg" in
    --force)   FORCE=true ;;
    --update)  UPDATE=true ;;
    --dry-run) DRY_RUN=true ;;
    -*)        fail "Unknown option: $arg" ;;
    *)         TARGET_DIR="$arg" ;;
  esac
done

if [[ "$FORCE" == true && "$UPDATE" == true ]]; then
  fail "--force and --update are mutually exclusive. Use --update to refresh harness-managed files while preserving user content; --force to overwrite everything."
fi

# Harness-managed CLAUDE.md guard markers. The generated CLAUDE.md wraps the
# toolkit-owned block in these; --update replaces only the guarded region.
CLAUDE_GUARD_BEGIN="<!-- BEGIN agent-dev-harness:managed (auto-generated — refreshed by install-to-project.sh --update; add your own content below the END marker) -->"
CLAUDE_GUARD_END="<!-- END agent-dev-harness:managed -->"

if [[ -z "$TARGET_DIR" ]]; then
  echo "Usage: $0 TARGET_DIR [--force] [--update] [--dry-run]" >&2
  echo "" >&2
  echo "  TARGET_DIR  Path to the project repo to install into." >&2
  exit 1
fi

TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$(dirname "$SCRIPT_DIR")"

[[ -d "$TARGET_DIR/.git" ]]          || fail "Not a git repository: $TARGET_DIR"
[[ "$TARGET_DIR" != "$SOURCE_DIR" ]] || fail "TARGET_DIR cannot be the agent-dev-harness repo itself."

TARGET_BRANCH=$(git -C "$TARGET_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
if [[ "$TARGET_BRANCH" == "main" || "$TARGET_BRANCH" == "master" ]]; then
  fail "Target project is on branch '$TARGET_BRANCH'. Create a feature branch first:
    cd $TARGET_DIR && git checkout -b setup/add-claude-tooling"
fi

# ---------------------------------------------------------------------------
# Derive marketplace metadata from this repo's git remote
# ---------------------------------------------------------------------------

ADP_MARKETPLACE_URL=$(git -C "$SOURCE_DIR" remote get-url origin \
  | sed 's|git@github.com:||; s|https://github.com/||; s|\.git$||') \
  || fail "Could not read git remote from $SOURCE_DIR"

# Read plugin name from the marketplace manifest
if command -v node &>/dev/null; then
  ADP_PLUGIN_NAME=$(node -e \
    "console.log(require('$SOURCE_DIR/.claude-plugin/marketplace.json').plugins[0].name)" \
    2>/dev/null) || ADP_PLUGIN_NAME="kf"
elif command -v python3 &>/dev/null; then
  ADP_PLUGIN_NAME=$(python3 -c \
    "import json; print(json.load(open('$SOURCE_DIR/.claude-plugin/marketplace.json'))['plugins'][0]['name'])" \
    2>/dev/null) || ADP_PLUGIN_NAME="kf"
else
  ADP_PLUGIN_NAME="kf"
fi

echo "Source   : $SOURCE_DIR"
echo "Target   : $TARGET_DIR"
echo "Toolkit  : $ADP_MARKETPLACE_URL (plugin: $ADP_PLUGIN_NAME)"
[[ "$DRY_RUN" == true ]] && echo "Mode     : DRY RUN — no files will be written"
[[ "$FORCE"   == true ]] && echo "Mode     : FORCE — existing files will be overwritten"
[[ "$UPDATE"  == true ]] && echo "Mode     : UPDATE — refreshing harness-managed files, preserving user content"
echo

# ---------------------------------------------------------------------------
# Helper: copy a single file, respecting --dry-run and --force
# ---------------------------------------------------------------------------

copy_file() {
  local src="$1"
  local dst="$2"
  local label="${3:-$(basename "$dst")}"
  if [[ ! -f "$src" ]]; then
    warn "Source not found, skipping: $src"
    return
  fi
  if [[ -f "$dst" ]] && [[ "$FORCE" != true ]] && [[ "$UPDATE" != true ]]; then
    warn "$label already exists — skipping (use --force or --update to overwrite)"
    return
  fi
  if [[ "$DRY_RUN" == true ]]; then
    ok "[dry-run] would copy $label"
    return
  fi
  mkdir -p "$(dirname "$dst")"
  cp -f "$src" "$dst"
  ok "$label"
}

# ---------------------------------------------------------------------------
# 1. .claude/rules/
# ---------------------------------------------------------------------------

step "Copying .claude/rules/"

RULES_SRC="$SOURCE_DIR/.claude/rules"
RULES_DST="$TARGET_DIR/.claude/rules"

if [[ ! -d "$RULES_SRC" ]]; then
  warn "No .claude/rules/ in source — skipping"
else
  [[ "$DRY_RUN" == false ]] && mkdir -p "$RULES_DST"
  for rule_file in "$RULES_SRC"/*.md; do
    copy_file "$rule_file" "$RULES_DST/$(basename "$rule_file")"
  done
fi

# ---------------------------------------------------------------------------
# 2. .claude/settings.json — merge hooks and enabledPlugins
# ---------------------------------------------------------------------------

step "Merging .claude/settings.json"

SETTINGS_SRC="$SOURCE_DIR/.claude/settings.json"
SETTINGS_DST="$TARGET_DIR/.claude/settings.json"

if [[ ! -f "$SETTINGS_SRC" ]]; then
  warn "No .claude/settings.json in source — skipping"
elif [[ "$DRY_RUN" == true ]]; then
  ok "[dry-run] would copy/merge settings.json"
else
  mkdir -p "$TARGET_DIR/.claude"
  if [[ ! -f "$SETTINGS_DST" ]]; then
    cp -f "$SETTINGS_SRC" "$SETTINGS_DST"
    ok "Created settings.json"
  elif ! command -v jq &>/dev/null; then
    warn "jq not found — skipping settings merge; review .claude/settings.json manually"
  else
    MERGED=$(jq -s '
      .[0] as $dst | .[1] as $src |
      ($dst.enabledPlugins // {}) * ($src.enabledPlugins // {}) as $plugins |
      reduce ($src.hooks // {} | to_entries[]) as $entry (
        $dst;
        .hooks[$entry.key] = (
          ((.hooks[$entry.key] // []) + $entry.value)
          | unique_by(.hooks[0].command)
        )
      ) |
      .enabledPlugins = $plugins
    ' "$SETTINGS_DST" "$SETTINGS_SRC")
    echo "$MERGED" > "$SETTINGS_DST"
    ok "Merged settings.json (hooks + enabledPlugins)"
  fi
fi

# ---------------------------------------------------------------------------
# 3. .claude/statusLine.sh
# ---------------------------------------------------------------------------

step "Copying .claude/statusLine.sh"
copy_file \
  "$SOURCE_DIR/.claude/statusLine.sh" \
  "$TARGET_DIR/.claude/statusLine.sh"
[[ "$DRY_RUN" == false ]] && chmod +x "$TARGET_DIR/.claude/statusLine.sh" 2>/dev/null || true

# ---------------------------------------------------------------------------
# 4. AGENTS.md
# ---------------------------------------------------------------------------

step "Copying AGENTS.md"
copy_file "$SOURCE_DIR/AGENTS.md" "$TARGET_DIR/AGENTS.md"

# ---------------------------------------------------------------------------
# 5. CLAUDE.md
# ---------------------------------------------------------------------------

step "Copying CLAUDE.md"

CLAUDE_SRC="$SOURCE_DIR/CLAUDE.md"
CLAUDE_DST="$TARGET_DIR/CLAUDE.md"

# Render the full target CLAUDE.md: title/intro, then the toolkit-owned sections
# wrapped in guard markers, then the user-editable sections (templated) BELOW the
# END guard. Keeping user content below the guard is what makes --update safe:
# the guarded region can be replaced wholesale without touching anything a
# developer has written.
render_claude_md() {
  awk -v gb="$CLAUDE_GUARD_BEGIN" -v ge="$CLAUDE_GUARD_END" '
    BEGIN { seen = 0; harness = "" }
    /^## Build & Test/          { seen = 1; cur = "skip"; next }
    /^## Architecture Overview/ { seen = 1; cur = "skip"; next }
    /^## Conventions & Patterns/{ seen = 1; cur = "skip"; next }
    /^## /                      { seen = 1; cur = "keep"; harness = harness $0 "\n"; next }
    {
      if (!seen)         { print; next }      # title + intro, before any section
      if (cur == "keep") { harness = harness $0 "\n" }
      # cur == "skip": drop the project-specific body (re-templated below)
    }
    END {
      print gb
      printf "%s", harness
      print ge
      print ""
      print "## Build & Test"
      print ""
      print "_Add your build and test commands here_"
      print ""
      print "```bash"
      print "# Example:"
      print "# npm install"
      print "# npm test"
      print "```"
      print ""
      print "## Architecture Overview"
      print ""
      print "_Add a brief overview of your project architecture_"
      print ""
      print "## Conventions & Patterns"
      print ""
      print "_Add your project-specific conventions here_"
    }
  ' "$CLAUDE_SRC"
}

if [[ ! -f "$CLAUDE_SRC" ]]; then
  warn "No CLAUDE.md in source — skipping"
elif [[ ! -f "$CLAUDE_DST" ]] || [[ "$FORCE" == true ]]; then
  # Fresh install or forced overwrite — render the whole file.
  if [[ "$DRY_RUN" == true ]]; then
    ok "[dry-run] would write CLAUDE.md (guarded harness block + templated project sections)"
  else
    render_claude_md > "$CLAUDE_DST"
    ok "CLAUDE.md (harness block guarded; project sections templated)"
  fi
elif [[ "$UPDATE" == true ]]; then
  # Refresh ONLY the guarded harness region; preserve everything else.
  if grep -qF "$CLAUDE_GUARD_BEGIN" "$CLAUDE_DST" && grep -qF "$CLAUDE_GUARD_END" "$CLAUDE_DST"; then
    if [[ "$DRY_RUN" == true ]]; then
      ok "[dry-run] would refresh guarded harness block in CLAUDE.md (user content preserved)"
    else
      NEWBLOCK_TMP=$(mktemp)
      SPLICE_TMP=$(mktemp)
      # Extract the freshly-rendered guarded region (BEGIN..END inclusive).
      render_claude_md \
        | awk -v gb="$CLAUDE_GUARD_BEGIN" -v ge="$CLAUDE_GUARD_END" \
            '$0==gb{f=1} f{print} $0==ge{exit}' > "$NEWBLOCK_TMP"
      # Replace the target's guarded region with the fresh block, in place.
      awk -v gb="$CLAUDE_GUARD_BEGIN" -v ge="$CLAUDE_GUARD_END" -v nb="$NEWBLOCK_TMP" '
        BEGIN { while ((getline line < nb) > 0) newblock = newblock line "\n" }
        $0 == gb            { printf "%s", newblock; skipping = 1; next }
        skipping && $0 == ge { skipping = 0; next }
        skipping            { next }
        { print }
      ' "$CLAUDE_DST" > "$SPLICE_TMP"
      mv "$SPLICE_TMP" "$CLAUDE_DST"
      rm -f "$NEWBLOCK_TMP"
      ok "CLAUDE.md (refreshed guarded harness block; user content preserved)"
    fi
  else
    warn "CLAUDE.md has no agent-dev-harness guard markers (legacy install) — skipping.
    Review upstream changes and re-run with --force to regenerate, or wrap the
    toolkit-managed block manually with these markers to make it update-ready:
      $CLAUDE_GUARD_BEGIN
      ...
      $CLAUDE_GUARD_END"
  fi
else
  warn "CLAUDE.md already exists — skipping (use --update to refresh the harness block, or --force to overwrite)"
fi

# ---------------------------------------------------------------------------
# 6. Update .gitignore to exclude toolkit-related secrets
# ---------------------------------------------------------------------------

step "Updating .gitignore"

GITIGNORE_DST="$TARGET_DIR/.gitignore"

# Patterns that should be gitignored
declare -a REQUIRED_PATTERNS=(
  "# Environment"
  ".env"
  ".env.*"
  "!.env.example"
  ""
  "# Claude Code per-developer overrides"
  ".claude/settings.local.json"
  ""
  "# Beads credentials"
  ".beads-credential-key"
)

if [[ "$DRY_RUN" == true ]]; then
  ok "[dry-run] would update .gitignore with toolkit patterns"
else
  # Create .gitignore if it doesn't exist
  [[ ! -f "$GITIGNORE_DST" ]] && touch "$GITIGNORE_DST"

  # Track if we added anything
  ADDED_PATTERNS=0

  # Check each pattern and add if missing
  for pattern in "${REQUIRED_PATTERNS[@]}"; do
    # Skip comment/header lines - always add them for context
    if [[ "$pattern" =~ ^#.* ]] || [[ -z "$pattern" ]]; then
      continue
    fi

    # Check if pattern exists (exact match or as part of a line)
    if ! grep -qF "$pattern" "$GITIGNORE_DST" 2>/dev/null; then
      # Add section header before first pattern in a group
      if [[ $ADDED_PATTERNS -eq 0 ]]; then
        echo "" >> "$GITIGNORE_DST"
        echo "# Added by agent-dev-harness toolkit" >> "$GITIGNORE_DST"
      fi

      # Find the comment header for this pattern
      for i in "${!REQUIRED_PATTERNS[@]}"; do
        if [[ "${REQUIRED_PATTERNS[$i]}" == "$pattern" ]]; then
          # Look backwards for comment header
          for ((j=i-1; j>=0; j--)); do
            if [[ "${REQUIRED_PATTERNS[$j]}" =~ ^#.* ]]; then
              # Add header if we haven't already
              if ! grep -qF "${REQUIRED_PATTERNS[$j]}" "$GITIGNORE_DST" 2>/dev/null; then
                [[ $j -gt 0 ]] && echo "" >> "$GITIGNORE_DST"
                echo "${REQUIRED_PATTERNS[$j]}" >> "$GITIGNORE_DST"
              fi
              break
            fi
          done
          break
        fi
      done

      echo "$pattern" >> "$GITIGNORE_DST"
      ((ADDED_PATTERNS++))
    fi
  done

  if [[ $ADDED_PATTERNS -gt 0 ]]; then
    ok "Updated .gitignore ($ADDED_PATTERNS patterns added)"
  else
    ok ".gitignore already has toolkit patterns"
  fi
fi

# ---------------------------------------------------------------------------
# 7. Brewfile
# ---------------------------------------------------------------------------

step "Copying Brewfile"
copy_file "$SOURCE_DIR/Brewfile" "$TARGET_DIR/Brewfile"

# ---------------------------------------------------------------------------
# 8. .env.example
# ---------------------------------------------------------------------------

step "Copying .env.example"
copy_file "$SOURCE_DIR/.env.example" "$TARGET_DIR/.env.example"

# ---------------------------------------------------------------------------
# 9. scripts/setup.sh (with URL injected)
# ---------------------------------------------------------------------------

step "Copying scripts/"

[[ "$DRY_RUN" == false ]] && mkdir -p "$TARGET_DIR/scripts"

# setup.sh: inject marketplace URL and plugin name before copying
SETUP_DST="$TARGET_DIR/scripts/setup.sh"
if [[ -f "$SETUP_DST" ]] && [[ "$FORCE" != true ]] && [[ "$UPDATE" != true ]]; then
  warn "setup.sh already exists — skipping (use --force or --update to overwrite)"
elif [[ "$DRY_RUN" == true ]]; then
  ok "[dry-run] would copy setup.sh (injecting ADP_MARKETPLACE_URL=$ADP_MARKETPLACE_URL, ADP_PLUGIN_NAME=$ADP_PLUGIN_NAME)"
else
  sed \
    -e "s|ADP_MARKETPLACE_URL=\"__INJECTED__\"|ADP_MARKETPLACE_URL=\"$ADP_MARKETPLACE_URL\"|" \
    -e "s|ADP_PLUGIN_NAME=\"__INJECTED__\"|ADP_PLUGIN_NAME=\"$ADP_PLUGIN_NAME\"|" \
    "$SOURCE_DIR/scripts/setup.sh" > "$SETUP_DST"
  ok "setup.sh (ADP_MARKETPLACE_URL=$ADP_MARKETPLACE_URL, ADP_PLUGIN_NAME=$ADP_PLUGIN_NAME)"
fi

# Make all copied scripts executable
if [[ "$DRY_RUN" == false ]]; then
  chmod +x "$TARGET_DIR/scripts/"*.sh 2>/dev/null || true
fi

# ---------------------------------------------------------------------------
# 10. .claude/settings.local.json — AWS Bedrock configuration
# ---------------------------------------------------------------------------

step "Configuring AWS Bedrock in settings.local.json"

SETTINGS_LOCAL_DST="$TARGET_DIR/.claude/settings.local.json"

# Read AWS_PROFILE_NAME from source .env.local or .env (agent-dev-harness repo)
# Try .env.local first (gitignored), then .env (may be source-controlled)
# The target project won't have .env yet - that's created after install
AWS_PROFILE_VALUE=""
if [[ -f "$SOURCE_DIR/.env.local" ]]; then
  # shellcheck source=/dev/null
  AWS_PROFILE_VALUE=$(grep '^AWS_PROFILE_NAME=' "$SOURCE_DIR/.env.local" 2>/dev/null | cut -d'=' -f2- | tr -d '"' || echo "")
elif [[ -f "$SOURCE_DIR/.env" ]]; then
  # shellcheck source=/dev/null
  AWS_PROFILE_VALUE=$(grep '^AWS_PROFILE_NAME=' "$SOURCE_DIR/.env" 2>/dev/null | cut -d'=' -f2- | tr -d '"' || echo "")
fi

# Fall back to placeholder if neither file exists or AWS_PROFILE_NAME not set
if [[ -z "$AWS_PROFILE_VALUE" ]]; then
  AWS_PROFILE_VALUE="<YOUR_AWS_SSO_PROFILE>"
  warn "Source .env.local/.env not found or AWS_PROFILE_NAME not set — using placeholder"
fi

if [[ "$DRY_RUN" == true ]]; then
  ok "[dry-run] would merge AWS config into settings.local.json (profile: $AWS_PROFILE_VALUE)"
elif ! command -v jq &>/dev/null; then
  warn "jq not found — skipping settings.local.json merge; configure AWS manually in $SETTINGS_LOCAL_DST"
else
  mkdir -p "$TARGET_DIR/.claude"

  # Create AWS config JSON
  AWS_CONFIG=$(jq -n \
    --arg profile "$AWS_PROFILE_VALUE" \
    '{
      awsAuthRefresh: ("aws sso login --profile " + $profile),
      env: {
        AWS_PROFILE: $profile,
        CLAUDE_CODE_USE_BEDROCK: "1",
        AWS_REGION: "us-east-1"
      }
    }')

  if [[ ! -f "$SETTINGS_LOCAL_DST" ]]; then
    # Create new settings.local.json
    echo "$AWS_CONFIG" > "$SETTINGS_LOCAL_DST"
    ok "Created settings.local.json with AWS config (profile: $AWS_PROFILE_VALUE)"
  else
    # Merge with existing settings.local.json
    MERGED=$(jq -s \
      --argjson aws_config "$AWS_CONFIG" \
      '.[0] as $existing | $existing * $aws_config | .env = (($existing.env // {}) * ($aws_config.env // {}))' \
      "$SETTINGS_LOCAL_DST")
    echo "$MERGED" > "$SETTINGS_LOCAL_DST"
    ok "Merged AWS config into settings.local.json (profile: $AWS_PROFILE_VALUE)"
  fi
fi

# ---------------------------------------------------------------------------
# 11. .claude/settings.local.json — Figma (optional, propagated if set)
# ---------------------------------------------------------------------------

step "Propagating Figma token (if set)"

FIGMA_TOKEN_VALUE=""
if [[ -f "$SOURCE_DIR/.env.local" ]]; then
  FIGMA_TOKEN_VALUE=$(grep '^FIGMA_API_TOKEN=' "$SOURCE_DIR/.env.local" 2>/dev/null | cut -d'=' -f2- | tr -d '"' || echo "")
elif [[ -f "$SOURCE_DIR/.env" ]]; then
  FIGMA_TOKEN_VALUE=$(grep '^FIGMA_API_TOKEN=' "$SOURCE_DIR/.env" 2>/dev/null | cut -d'=' -f2- | tr -d '"' || echo "")
fi

if [[ -z "$FIGMA_TOKEN_VALUE" ]]; then
  ok "FIGMA_API_TOKEN not set in source — skipping (run setup.sh in target project to configure)"
elif [[ "$DRY_RUN" == true ]]; then
  ok "[dry-run] would add FIGMA_API_TOKEN to settings.local.json"
elif ! command -v jq &>/dev/null; then
  warn "jq not found — skipping Figma token propagation"
else
  mkdir -p "$TARGET_DIR/.claude"
  if [[ ! -f "$SETTINGS_LOCAL_DST" ]]; then
    jq -n --arg token "$FIGMA_TOKEN_VALUE" '{env: {FIGMA_API_TOKEN: $token}}' > "$SETTINGS_LOCAL_DST"
    ok "Created settings.local.json with FIGMA_API_TOKEN"
  else
    MERGED=$(jq --arg token "$FIGMA_TOKEN_VALUE" '.env.FIGMA_API_TOKEN = $token' "$SETTINGS_LOCAL_DST")
    echo "$MERGED" > "$SETTINGS_LOCAL_DST"
    ok "Added FIGMA_API_TOKEN to settings.local.json"
  fi
fi

# ---------------------------------------------------------------------------
# Done — hand off to the developer
# ---------------------------------------------------------------------------

echo ""
if [[ "$UPDATE" == true ]]; then
  echo -e "${GREEN}Harness-managed files refreshed in $TARGET_DIR${NC}"
  echo ""
  echo "  Review the changes before committing:"
  echo ""
  echo -e "    ${YELLOW}cd $TARGET_DIR && git diff${NC}"
  echo ""
else
  echo -e "${GREEN}Files installed into $TARGET_DIR${NC}"
  echo ""
  echo "  Next step — switch to your project and run setup:"
  echo ""
  echo -e "    ${YELLOW}cd $TARGET_DIR${NC}"
  echo -e "    ${YELLOW}cp .env.example .env${NC}   # then set AWS_PROFILE_NAME"
  echo -e "    ${YELLOW}./scripts/setup.sh${NC}"
  echo ""
fi

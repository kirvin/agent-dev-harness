#!/usr/bin/env bash
# setup.sh — Set up this project for Claude Code via AWS Bedrock.
#
# Usage (from this project's root directory):
#   ./scripts/setup.sh
#
# This script is installed into your project by agent-dev-harness/scripts/install-to-project.sh.
# Do not run it from the agent-dev-harness directory itself.
# Safe to re-run: all steps are guarded by existence checks.

set -euo pipefail

# ---------------------------------------------------------------------------
# Injected by install-to-project.sh at copy time — do not edit manually
# ---------------------------------------------------------------------------
ADP_MARKETPLACE_URL="__INJECTED__"
ADP_PLUGIN_NAME="__INJECTED__"
# ---------------------------------------------------------------------------

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

ok()   { echo -e "${GREEN}✓${NC}  $*"; }
warn() { echo -e "${YELLOW}!${NC}  $*"; }
fail() { echo -e "${RED}✗${NC}  $*" >&2; exit 1; }
step() { echo -e "\n${YELLOW}=>${NC} $*"; }

# Guard: catch accidental execution of the uninstalled template
if [[ "$ADP_MARKETPLACE_URL" == "__INJECTED__" ]]; then
  fail "This script has not been installed into a project yet.
  Run install-to-project.sh from the agent-dev-harness repo:
    ./scripts/install-to-project.sh /path/to/your-project"
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ADP_MARKETPLACE_NAME="${ADP_MARKETPLACE_URL##*/}"

echo "Project  : $REPO_ROOT"
echo "Toolkit  : $ADP_MARKETPLACE_URL ($ADP_PLUGIN_NAME plugin)"
echo

# ──────────────────────────────────────────────
# 1. Homebrew
# ──────────────────────────────────────────────
step "Checking Homebrew..."
if ! command -v brew &>/dev/null; then
  warn "Homebrew not found. Installing..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  [[ -f /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"
fi
ok "Homebrew: $(brew --version | head -1)"

# ──────────────────────────────────────────────
# 2. Install dependencies from Brewfile
# ──────────────────────────────────────────────
step "Installing dependencies from Brewfile..."
if [[ ! -f "$REPO_ROOT/Brewfile" ]]; then
  warn "No Brewfile found in project root — skipping"
else
  HOMEBREW_NO_AUTO_UPDATE=1 brew bundle --file="$REPO_ROOT/Brewfile"
  ok "All Brewfile dependencies installed"
fi

# ──────────────────────────────────────────────
# 3. .env file (.env.local takes precedence)
# ──────────────────────────────────────────────
step "Checking .env..."
ENV_FILE="$REPO_ROOT/.env"
ENV_LOCAL_FILE="$REPO_ROOT/.env.local"

# Try .env.local first (gitignored), then .env (may be source-controlled)
if [[ -f "$ENV_LOCAL_FILE" ]]; then
  # shellcheck source=/dev/null
  source "$ENV_LOCAL_FILE"
  ENV_SOURCE=".env.local"
elif [[ -f "$ENV_FILE" ]]; then
  # shellcheck source=/dev/null
  source "$ENV_FILE"
  ENV_SOURCE=".env"
else
  fail ".env not found. Copy .env.example and fill in your AWS profile name:
    cp $REPO_ROOT/.env.example $REPO_ROOT/.env
  Or create .env.local (gitignored) if .env is source-controlled."
fi

if [[ -z "${AWS_PROFILE_NAME:-}" ]]; then
  fail "AWS_PROFILE_NAME is not set in $ENV_SOURCE. Edit $REPO_ROOT/$ENV_SOURCE."
fi
ok "$ENV_SOURCE loaded (AWS_PROFILE_NAME=$AWS_PROFILE_NAME)"

# ──────────────────────────────────────────────
# 4. AWS Bedrock model access
# ──────────────────────────────────────────────
step "Checking Bedrock access..."
if ! aws bedrock list-foundation-models --profile "$AWS_PROFILE_NAME" &>/dev/null; then
  warn "Could not reach AWS Bedrock."
  echo "    Verify your IAM role has the 'bedrock:InvokeModel' permission"
  echo "    and that Claude models are enabled in the AWS Bedrock console."
else
  ok "Bedrock reachable."
fi

# ──────────────────────────────────────────────
# 5. Claude Code
# ──────────────────────────────────────────────
step "Checking Claude Code..."
if ! command -v claude &>/dev/null; then
  fail "Claude Code not found. Install it: brew install --cask claude-code"
fi
ok "Claude Code: $(claude --version 2>/dev/null | head -1)"

# ──────────────────────────────────────────────
# 6. Register plugin marketplaces (once per developer machine)
# ──────────────────────────────────────────────
step "Registering plugin marketplaces..."

MARKETPLACE_DIR="$HOME/.claude/plugins/marketplaces"
PLUGIN_CACHE="$HOME/.claude/plugins/cache"

if [[ ! -d "$MARKETPLACE_DIR/$ADP_MARKETPLACE_NAME" ]]; then
  echo "    Registering $ADP_MARKETPLACE_NAME marketplace ($ADP_MARKETPLACE_URL)..."
  claude plugin marketplace add "$ADP_MARKETPLACE_URL" \
    && ok "Registered $ADP_MARKETPLACE_NAME marketplace" \
    || warn "Failed — run manually: claude plugin marketplace add $ADP_MARKETPLACE_URL"
else
  ok "$ADP_MARKETPLACE_NAME marketplace already registered"
fi

if [[ ! -d "$MARKETPLACE_DIR/claude-essentials" ]]; then
  echo "    Registering claude-essentials marketplace..."
  claude plugin marketplace add rileyhilliard/claude-essentials \
    && ok "Registered claude-essentials marketplace" \
    || warn "Failed — run manually: claude plugin marketplace add rileyhilliard/claude-essentials"
else
  ok "claude-essentials marketplace already registered"
fi

# ──────────────────────────────────────────────
# 7. Install plugins into this project
# ──────────────────────────────────────────────
step "Installing plugins..."

cd "$REPO_ROOT"

if [[ ! -d "$PLUGIN_CACHE/$ADP_MARKETPLACE_NAME/$ADP_PLUGIN_NAME" ]]; then
  echo "    Installing ${ADP_PLUGIN_NAME}@${ADP_MARKETPLACE_NAME}..."
  claude plugin install "${ADP_PLUGIN_NAME}@${ADP_MARKETPLACE_NAME}" --scope project \
    && ok "Installed ${ADP_PLUGIN_NAME} plugin" \
    || warn "Failed — run manually: claude plugin install ${ADP_PLUGIN_NAME}@${ADP_MARKETPLACE_NAME} --scope project"
else
  ok "${ADP_PLUGIN_NAME} plugin already installed"
fi

if [[ ! -d "$PLUGIN_CACHE/claude-essentials/ce" ]]; then
  echo "    Installing ce@claude-essentials..."
  claude plugin install ce@claude-essentials --scope project \
    && ok "Installed ce plugin" \
    || warn "Failed — run manually: claude plugin install ce@claude-essentials --scope project"
else
  ok "ce plugin already installed"
fi

# ──────────────────────────────────────────────
# 8. Beads issue tracker
# ──────────────────────────────────────────────
step "Checking Beads..."
if ! command -v bd &>/dev/null; then
  fail "bd not found. Install it: brew install beads"
fi
ok "beads: $(bd --version 2>/dev/null | head -1)"

if [[ ! -d "$REPO_ROOT/.beads" ]]; then
  warn ".beads not initialized for this project."
  echo ""
  echo "    Beads uses a short prefix to namespace issue IDs (e.g. 'myproj' → myproj-001...)."
  echo "    Use a lowercase abbreviation of this project's name."
  echo ""
  read -r -p "    Enter your beads prefix (or press Enter to skip): " BEADS_PREFIX

  if [[ -z "$BEADS_PREFIX" ]]; then
    warn "Skipping — run manually: bd init --shared-server --prefix <prefix>"
  elif ! [[ "$BEADS_PREFIX" =~ ^[a-z0-9]+$ ]]; then
    warn "Invalid prefix (must be lowercase alphanumeric) — skipping"
  else
    cd "$REPO_ROOT" && bd init --shared-server --prefix "$BEADS_PREFIX" \
      && ok "Beads initialized with prefix '$BEADS_PREFIX'" \
      || warn "bd init failed — run manually: bd init --shared-server --prefix $BEADS_PREFIX"
  fi
else
  ok "Beads already initialized"
fi

# ──────────────────────────────────────────────
# 9. Git hooks
# ──────────────────────────────────────────────
step "Checking git hooks..."
if [[ -d "$REPO_ROOT/.beads" ]] && [[ ! -f "$REPO_ROOT/.git/hooks/pre-commit" ]]; then
  cd "$REPO_ROOT" && bd hooks install \
    && ok "Git hooks installed" \
    || warn "bd hooks install failed — run manually"
else
  ok "Git hooks already installed"
fi

# ──────────────────────────────────────────────
# 10. Figma integration (optional)
# ──────────────────────────────────────────────
step "Figma integration (optional)..."

ENV_ACTIVE_FILE="${ENV_LOCAL_FILE:-$ENV_FILE}"

if grep -q 'FIGMA_API_TOKEN' "$ENV_ACTIVE_FILE" 2>/dev/null; then
  ok "FIGMA_API_TOKEN already set in $(basename "$ENV_ACTIVE_FILE") — skipping"
else
  echo "    The figma-to-spec skill converts Figma design URLs into structured specs."
  echo "    A personal access token is required (Figma → Settings → Account → Personal access tokens)."
  echo ""
  read -r -p "    Set up Figma integration? [y/N] " FIGMA_ANSWER
  if [[ "${FIGMA_ANSWER,,}" == "y" ]]; then
    read -r -p "    Paste your Figma personal access token: " FIGMA_TOKEN
    if [[ -n "$FIGMA_TOKEN" ]]; then
      echo "FIGMA_API_TOKEN=$FIGMA_TOKEN" >> "$ENV_ACTIVE_FILE"
      ok "FIGMA_API_TOKEN written to $(basename "$ENV_ACTIVE_FILE")"
    else
      warn "Empty token — skipping. Set FIGMA_API_TOKEN manually when ready."
    fi
  else
    ok "Skipped — set FIGMA_API_TOKEN in .env.local later if needed"
  fi
fi

# ──────────────────────────────────────────────
# Done
# ──────────────────────────────────────────────
echo ""
echo -e "${GREEN}Setup complete.${NC}"
echo ""
echo "  Start Claude Code (via Bedrock):"
echo "    cd $REPO_ROOT"
echo "    claude code ."
echo ""
echo "  See available work:"
echo "    bd ready"
echo ""

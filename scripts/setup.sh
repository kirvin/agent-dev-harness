#!/usr/bin/env bash
# setup.sh — Set up this project for Claude Code (Pro/Max subscription auth).
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
# 3. .env file (optional — for integrations like Figma)
# ──────────────────────────────────────────────
step "Checking .env..."
ENV_FILE="$REPO_ROOT/.env"
ENV_LOCAL_FILE="$REPO_ROOT/.env.local"

# Try .env.local first (gitignored), then .env (may be source-controlled).
# Neither is required: Claude Code auth uses your Pro/Max subscription, not env vars.
if [[ -f "$ENV_LOCAL_FILE" ]]; then
  # shellcheck source=/dev/null
  source "$ENV_LOCAL_FILE"
  ok ".env.local loaded"
elif [[ -f "$ENV_FILE" ]]; then
  # shellcheck source=/dev/null
  source "$ENV_FILE"
  ok ".env loaded"
else
  ok "No .env found — skipping (only needed for optional integrations like Figma)"
fi

# ──────────────────────────────────────────────
# 4. Claude Code
# ──────────────────────────────────────────────
step "Checking Claude Code..."
if ! command -v claude &>/dev/null; then
  fail "Claude Code not found. Install it: brew install --cask claude-code"
fi
ok "Claude Code: $(claude --version 2>/dev/null | head -1)"
echo "    Auth: this toolkit uses your Claude Pro/Max subscription."
echo "    If you're not logged in yet, run 'claude' and choose 'Log in with your Anthropic account'."

# ──────────────────────────────────────────────
# 5. Register plugin marketplaces (once per developer machine)
# ──────────────────────────────────────────────

MARKETPLACE_DIR="$HOME/.claude/plugins/marketplaces"

# True when <plugin-id> (e.g. kf@agent-dev-harness) is actually ENABLED for this
# project — user scope, or project scope matching this repo. We check enablement
# rather than cache-dir presence so a cached-but-disabled plugin self-heals.
plugin_enabled() {
  command -v jq &>/dev/null || return 1
  claude plugin list --json 2>/dev/null \
    | jq -e --arg id "$1" --arg proj "$REPO_ROOT" \
        'any(.[]; .id == $id and .enabled == true
                  and (.scope == "user" or .projectPath == $proj))' \
        >/dev/null 2>&1
}

# Install + enable a plugin at project scope, idempotently. install handles the
# not-cached case; enable handles the cached-but-disabled case.
ensure_plugin() {
  local id="$1" label="${2:-$1}"
  if plugin_enabled "$id"; then
    ok "$label plugin already enabled"
    return
  fi
  echo "    Installing/enabling $id..."
  claude plugin install "$id" --scope project >/dev/null 2>&1 || true
  claude plugin enable  "$id" --scope project >/dev/null 2>&1 || true
  if plugin_enabled "$id"; then
    ok "Enabled $label plugin"
  else
    warn "Could not enable $id — run manually:
    claude plugin install $id --scope project && claude plugin enable $id --scope project"
  fi
}

step "Registering plugin marketplaces..."

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

# Remove stale installs left over from earlier marketplace names. This repo was
# renamed agent-dev-plugins → claude-config → agent-dev-harness; old installs
# (kf@claude-config, kf@agent-dev-plugins) linger as disabled duplicates.
STALE_MARKETPLACES="claude-config agent-dev-plugins"
if command -v jq &>/dev/null; then
  CLEANED=0
  while IFS=$'\t' read -r stale_id stale_scope; do
    [[ -z "$stale_id" ]] && continue
    echo "    Uninstalling stale $stale_id ($stale_scope)..."
    if claude plugin uninstall "$stale_id" --scope "$stale_scope" -y >/dev/null 2>&1; then
      ok "Removed stale $stale_id ($stale_scope)"; CLEANED=1
    else
      warn "Could not remove $stale_id — run: claude plugin uninstall $stale_id --scope $stale_scope -y"
    fi
  done < <(
    claude plugin list --json 2>/dev/null \
      | jq -r --arg ms "$STALE_MARKETPLACES" \
          '($ms | split(" ")) as $stale
           | .[] | select((.id | split("@")[1]) as $m | $stale | index($m))
           | "\(.id)\t\(.scope)"' \
      | sort -u
  )
  for ms in $STALE_MARKETPLACES; do
    if [[ -d "$MARKETPLACE_DIR/$ms" ]]; then
      claude plugin marketplace remove "$ms" >/dev/null 2>&1 \
        && { ok "Deregistered stale marketplace: $ms"; CLEANED=1; } \
        || warn "Could not deregister marketplace $ms — run: claude plugin marketplace remove $ms"
    fi
  done
  [[ "$CLEANED" == 0 ]] && ok "No stale plugins or marketplaces found"
else
  warn "jq not found — skipping stale-plugin cleanup"
fi

# ──────────────────────────────────────────────
# 6. Install plugins into this project
# ──────────────────────────────────────────────
step "Installing plugins..."

cd "$REPO_ROOT"

ensure_plugin "${ADP_PLUGIN_NAME}@${ADP_MARKETPLACE_NAME}" "$ADP_PLUGIN_NAME"
ensure_plugin "ce@claude-essentials" "ce"

# ──────────────────────────────────────────────
# 7. Beads issue tracker
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
# 8. Git hooks
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
# 9. Figma integration (optional)
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
  if [[ "$FIGMA_ANSWER" == [Yy] ]]; then
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
echo "  Start Claude Code (log in with your Anthropic Pro/Max account if prompted):"
echo "    cd $REPO_ROOT"
echo "    claude"
echo ""
echo "  See available work:"
echo "    bd ready"
echo ""

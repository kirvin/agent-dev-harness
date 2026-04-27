# Project Instructions for AI Agents

This file provides instructions and context for AI coding agents working on this project.

<!-- BEGIN BEADS INTEGRATION v:1 profile:minimal hash:ca08a54f -->
## Beads Issue Tracker

This project uses **bd (beads)** for issue tracking. Run `bd prime` to see full workflow context and commands.

### Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --claim  # Claim work
bd close <id>         # Complete work
```

### Rules

- Use `bd` for ALL task tracking — do NOT use TodoWrite, TaskCreate, or markdown TODO lists
- Run `bd prime` for detailed command reference and session close protocol
- Use `bd remember` for persistent knowledge — do NOT use MEMORY.md files

## Session Completion

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   bd dolt push
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds
<!-- END BEADS INTEGRATION -->


## Build & Test

No build step. Scripts are plain bash — validate syntax with:

```bash
bash -n scripts/<script>.sh
node scripts/generate-plugin-skills.js --dry-run
```

## Purpose & Owner

This is **@kirvin's personal Claude Code toolkit** (`github.com/kirvin/agent-dev-harness`). It distributes a consistent set of rules, skills, plugins, and workflow conventions across all of kirvin's personal projects.

Two things happen here:

1. **Plugin authoring** — All custom skills live in `plugins/kf/`. When a consuming project runs `claude plugin update kf@agent-dev-harness`, it pulls from this repo.
2. **Project provisioning** — `scripts/install-to-project.sh` copies rules, scripts, and AWS Bedrock config into any existing project. `scripts/new-project.sh` creates a new repo from scratch.

If you're working in a project that has the `kf` plugin installed and something is wrong with a skill, the source is in `plugins/kf/skills/` here. If a rule needs to change across all projects, update it here and re-run `install-to-project.sh --force` against each project.

> Note: this repo was previously named `agent-dev-plugins` and then `claude-config`. If you see either name anywhere in comments or error messages, it's stale and should be updated to `agent-dev-harness`.

## Architecture Overview

Key components:

- `plugins/kf/` — All custom skills. Two categories:
  - **Hand-authored** (`spec-first`, `repo-knowledge-*`, `task-completion`, `retro`, `session-close`, `ui-ux-pro-max`): edit directly in `plugins/kf/skills/`
  - **Generated** (design skill wrappers like `design-taste-frontend`, `high-end-visual-design`, etc.): source lives in `.agents/skills/`, synced into `plugins/kf/skills/` via `make plugin-release`
- `.claude/rules/` — Rule files that trigger skill activations and enforce workflow patterns. Copied into target projects by `install-to-project.sh`.
- `scripts/install-to-project.sh` — Copies the toolkit into an existing project repo (includes AWS Bedrock config). Run via `make install-to-project target=/path/to/project`. Safe to re-run; use `force=1` to overwrite.
- `scripts/new-project.sh` — Creates a new private GitHub repo under the kirvin account and runs the full install sequence.
- `scripts/setup.sh` — Per-machine setup (Homebrew, AWS, plugins, beads). This file is a template; `install-to-project.sh` injects `ADP_MARKETPLACE_URL` and `ADP_PLUGIN_NAME` before copying it into a target project. Do not run it from this repo directly.
- `scripts/generate-plugin-skills.js` — Syncs `.agents/skills/` into `plugins/kf/skills/` (for the generated design skill wrappers).

## Secure Coding

All code in this repo and in projects provisioned by it must follow these rules:

- **No hardcoded credentials** — secrets belong in `.env` (gitignored) or AWS Secrets Manager; never in source files
- **No secrets in log output** — error messages and debug output must not contain tokens, passwords, or keys
- **Validate at boundaries** — validate user input and external API responses before using them; trust internal code
- **Safe error messages** — do not expose stack traces, internal paths, or system details to untrusted callers
- **External service credentials** — always sourced from `.env`; provide `.env.example` with placeholder values
- **New integrations require a threat model** — at minimum one STRIDE pass before merging; document findings in the PR

When adding credentials to setup scripts, guard every step so re-runs are safe and never overwrite existing values without prompting.

## Conventions & Patterns

- Scripts use `#!/usr/bin/env bash` and `set -euo pipefail`
- All scripts resolve `REPO_ROOT` via `BASH_SOURCE[0]` before using relative paths
- `.env` is always sourced from `$REPO_ROOT/.env` (never relative `./`)
- Design skill wrappers in `plugins/kf/skills/` are generated, not hand-edited — edit source in `.agents/skills/`, then run `make plugin-release`
- Plugin version bumps are required for `claude plugin update` to pick up changes — see `docs/deployment-and-release.md`

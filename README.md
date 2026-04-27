# agent-dev-harness

Personal Claude Code toolkit for [@kirvin](https://github.com/kirvin). Distributes a consistent set of rules, skills, plugins, and workflow conventions across all of kirvin's personal projects.

## What this is

This repo serves two purposes:

1. **Plugin marketplace** — hosts the `kf` plugin, which bundles all custom skills (workflow methodology, design, repo knowledge, session lifecycle). Projects point Claude Code here to install and update the plugin.
2. **Project installer** — `scripts/install-to-project.sh` copies the rules, workflow conventions, and AWS Bedrock config into any existing project repo. `scripts/new-project.sh` creates a new repo from scratch with everything already configured.

If you're working on a project that has the `kf` plugin installed, this is where those skills live. If something in the Claude Code workflow feels wrong in one of kirvin's projects, the source is probably here.

## What's included

```
plugins/
  kf/             — All custom skills (spec-first, design, repo knowledge, session lifecycle)

.claude/
  rules/
    beads-github.md       — Close beads issues linked to GitHub issues
    debugging.md          — Activates ce:systematic-debugging
    design-skills.md      — Auto-activates design skills for UI/frontend tasks
    error-handling.md     — No silent failures; activates ce:handling-errors
    git.md                — Commit message conventions (includes beads task ID)
    npm.md                — Cross-platform lockfile conventions
    planning.md           — After writing a plan, create beads issues immediately
    requirements.md       — Keep docs/requirements.md accurate when features ship
    testing.md            — Activates ce:writing-tests and ce:fixing-flaky-tests
    tdd.md                — Red-Green-Refactor for all features and bugs
    verification.md       — Run lint/build/tests before claiming work is done

scripts/
  new-project.sh          — Create a new repo pre-configured with this toolkit
  install-to-project.sh   — Install this toolkit into an existing repo
  setup.sh                — Per-machine setup (Homebrew, AWS, plugins, beads); copied into target projects by install-to-project.sh
  generate-plugin-skills.js — Sync .agents/skills/ into plugins/kf/skills/

CLAUDE.md                 — Template project entry point
skills-lock.json          — Pinned community skills (restored via npx skills)
```

## Setting up a new project

```bash
# From the claude-config root:
./scripts/new-project.sh "My Project Name"
```

This creates a private GitHub repo under kirvin's account, copies the config layer in, initializes beads, and prints the next steps.

For an existing repo:

```bash
./scripts/install-to-project.sh /path/to/your-project
# Then, in the target project:
cd /path/to/your-project && ./scripts/setup.sh
```

`install-to-project.sh` is safe to re-run. Use `--force` to overwrite files that already exist.

## Prerequisites (one-time per machine)

1. Install [Claude Code](https://claude.ai/code)
2. Install Beads: `brew install beads`
3. Install the `ce` plugin (inside a Claude Code session):
   ```
   /plugin marketplace add https://github.com/rileyhilliard/claude-essentials
   /plugin install ce
   ```
4. Configure `~/.claude/settings.json`:
   ```json
   {
     "effortLevel": "medium",
     "model": "sonnet",
     "hooks": {
       "SessionStart": [{ "command": "bd prime", "type": "command" }],
       "PreCompact":   [{ "command": "bd prime", "type": "command" }]
     }
   }
   ```

## Customizing after install

- **`CLAUDE.md`** — Update doc links to match your project's actual docs
- **`.claude/rules/npm.md`** — Remove or adapt if not using npm
- **`.claude/rules/requirements.md`** — Update the path to your requirements doc, or remove
- **`.claude/rules/design-skills.md`** — Remove skills irrelevant to your stack

## Managing skills

Add a skill:
```bash
npx skills add <owner/repo@skill-name>
git add skills-lock.json && git commit -m "chore: add <skill-name> skill"
```

Update all skills to latest:
```bash
npx skills update
git add skills-lock.json && git commit -m "chore: update skills"
```

## Releasing plugin updates

See `docs/deployment-and-release.md` for the full release process. Short version:

1. Edit skills under `plugins/kf/`
2. Bump the version in the plugin's `.claude-plugin/plugin.json`
3. Push — consuming projects update with `claude plugin update kf@agent-dev-harness`

## Propagating config changes to existing projects

Rules and scripts aren't auto-synced. To push an update to an existing project:

```bash
./scripts/install-to-project.sh /path/to/existing-project --force
```

This re-copies changed files. Review the diff in the target project before committing.

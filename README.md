# claude-config

Reusable Claude Code configuration — rules, skills, and workflow conventions for consistent AI-assisted development across projects.

## What's included

```
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
CLAUDE.md                 — Template project entry point
skills-lock.json          — Pinned community skills (restored via npx skills)
```

## New project setup

### Prerequisites (one-time per machine)

1. Install [Claude Code](https://claude.ai/code)
2. Install Beads: `brew install beads`
3. Install the `ce` plugin — inside a Claude Code session:
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

### Per project

```bash
# 1. Copy this config layer into your project root
cp -r /path/to/claude-config/.claude .
cp /path/to/claude-config/skills-lock.json .
cp /path/to/claude-config/CLAUDE.md .   # then customize

# 2. Restore skills
npx skills experimental_install --yes --agent claude-code

# 3. Initialize Beads
bd init --shared-server
bd hooks install

# 4. Commit
git add .claude/ skills-lock.json CLAUDE.md .beads/
git commit -m "chore: add Claude Code configuration"
```

### Customize for your project

After copying, update:

- **`CLAUDE.md`** — Update the doc links to match your project's actual docs
- **`.claude/rules/npm.md`** — Remove if not using npm, or adapt the Docker lockfile command to your setup
- **`.claude/rules/requirements.md`** — Update the path to your requirements doc, or remove if not using this convention
- **`.claude/rules/design-skills.md`** — Remove skills that aren't relevant to your stack

## Updating skills

To add a new skill:
```bash
npx skills add <owner/repo@skill-name>
# commit the updated skills-lock.json
git add skills-lock.json && git commit -m "chore: add <skill-name> skill"
```

To update all skills to latest:
```bash
npx skills update
git add skills-lock.json && git commit -m "chore: update skills"
```

## Keeping rules in sync across projects

Currently manual: update rules here, then copy changed files to other projects.

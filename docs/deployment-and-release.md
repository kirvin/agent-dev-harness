# Deployment & Release

This document covers how to release a new version of the `kf` plugin and propagate changes to consuming projects.

## How the Plugin System Works

The `kf` plugin is installed into projects via the `agent-dev-harness` marketplace:

```
kirvin/agent-dev-harness  (GitHub)
  └── .claude-plugin/marketplace.json   ← registers this repo as a marketplace
  └── plugins/kf/
        ├── .claude-plugin/plugin.json  ← version lives here
        └── skills/                     ← skill SKILL.md files live here
```

Claude Code determines whether an update is available by comparing the version in `plugin.json` against the installed version. **A version bump is required for `claude plugin update` to pull new changes.**

## Release Process

Releases are automatic. Every push to `main` runs `.github/workflows/release.yml`,
which runs [intuit/auto](https://intuit.github.io/auto/) (`auto shipit`). Do not
edit the version in `plugin.json` by hand.

### 1. Make your changes on a branch

Edit skill files, add new skills, or update rules under `plugins/kf/`.

### 2. Write Conventional Commits

The commit type decides the release. CI fails a PR whose title or any non-merge
commit subject is not in this format (`scripts/check-conventional-commits.sh`).

| Commit | Release | Use for |
|--------|---------|---------|
| `fix(scope): ...` | patch (`1.4.5` → `1.4.6`) | changed skill or rule behaviour, bug fixes |
| `feat(scope): ...` | minor (`1.4.5` → `1.5.0`) | new skill, new capability |
| `feat!: ...` or a `BREAKING CHANGE:` footer | major (`1.4.5` → `2.0.0`) | skill renamed or removed |
| `docs:`, `chore:`, `ci:`, `build:`, `test:`, `refactor:`, `style:`, `perf:` | none by itself | changes consumers don't need to pull |

A release covers everything merged since the previous GitHub release. If the
newest merged PR is a no-release type, nothing ships yet; those changes go out
with the next `fix` or `feat`.

### 3. Merge the PR

On merge, `auto shipit`:
- bumps `plugins/kf/.claude-plugin/plugin.json`
- commits `chore(release): kf vX.Y.Z` on `main`
- pushes an annotated `vX.Y.Z` tag
- publishes GitHub release notes grouped by change type

A local plugin handles the version file (`scripts/auto-plugin-json.js`). The
decision record is `docs/adr/ADR-001-release-automation.md`.

To preview what the next release would be:

```bash
npm ci --ignore-scripts
GH_TOKEN=$(gh auth token) npx auto version        # prints the bump, or nothing
GH_TOKEN=$(gh auth token) npx auto latest --dry-run --no-changelog
```

### 4. Update in each consuming project

In each project that has the `kf` plugin installed:

```bash
claude plugin update kf@agent-dev-harness --scope project
```

Then **restart the Claude Code session** to apply the changes. New and updated skills won't appear until the session is restarted.

---

## Rapid Iteration (Skip Version Bumps)

When iterating quickly on skill content, force-reinstalling bypasses the version check:

```bash
claude plugin uninstall kf@agent-dev-harness --scope project
claude plugin install kf@agent-dev-harness
```

This always pulls the latest commit from GitHub regardless of version. Use this during development; merged `fix`/`feat` PRs produce the versioned releases.

---

## Adding a New Skill

### Native skill (content lives in the plugin)

Add a directory under `plugins/kf/skills/<skill-name>/`:

```
plugins/kf/skills/my-skill/
├── SKILL.md              ← required; frontmatter + skill content
└── references/           ← optional; files Claude reads on demand
    └── some-reference.md
```

`SKILL.md` frontmatter:
```markdown
---
name: my-skill
description: One-line description shown in the skill picker and system prompt.
---

# Skill content here...
```

The skill becomes available as `kf:my-skill` after install + session restart.

### Wrapper skill (delegates to `.agents/skills/`)

For skills installed via `npx skills experimental_install` (the skills.sh ecosystem), add a thin wrapper that tells Claude to read the actual content from the project's local installation:

```markdown
---
name: my-skill
description: <copy description from the upstream SKILL.md>
---

This skill delegates to the project's locally installed skill. Read and apply the full content now:

\`\`\`
.agents/skills/my-skill/SKILL.md
\`\`\`

Use the Read tool to load that file, then follow all its instructions completely.

> If the file doesn't exist, run `npx skills experimental_install` in the project root.
```

If the skill has reference files, add a note:
```markdown
This skill also has reference files in `.agents/skills/my-skill/references/` — load the relevant ones as instructed by the main SKILL.md.
```

---

## Checking What's Installed

```bash
# List all installed plugins and versions
claude plugin list

# Check the kf plugin version currently active in this project
claude plugin list | grep kf
```

---

## Skills That Need Project-Side Installation

The following `kf` skills are wrappers — they require `npx skills experimental_install` to have been run in the consuming project:

| Skill | Upstream source |
|-------|----------------|
| `kf:design-taste-frontend` | `Leonxlnx/taste-skill` |
| `kf:stitch-design-taste` | `Leonxlnx/taste-skill` |
| `kf:high-end-visual-design` | `Leonxlnx/taste-skill` |
| `kf:minimalist-ui` | `Leonxlnx/taste-skill` |
| `kf:redesign-existing-projects` | `Leonxlnx/taste-skill` |
| `kf:industrial-brutalist-ui` | `Leonxlnx/taste-skill` |
| `kf:full-output-enforcement` | `Leonxlnx/taste-skill` |
| `kf:ui-animation` | `mblode/agent-skills` |

Skills that are fully self-contained in the plugin (no project-side install needed):

| Skill | Notes |
|-------|-------|
| `kf:spec-first` | Native skill with reference files |

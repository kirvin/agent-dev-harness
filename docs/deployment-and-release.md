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

### 1. Make your changes

Edit skill files, add new skills, or update rules under `plugins/kf/`.

### 2. Bump the version in `plugin.json`

```bash
# plugins/kf/.claude-plugin/plugin.json
{
  "version": "1.2.0"   # increment patch, minor, or major as appropriate
}
```

Use standard semver conventions:
| Change type | Bump |
|-------------|------|
| New skill added | minor (`1.1.0` → `1.2.0`) |
| Existing skill updated | patch (`1.2.0` → `1.2.1`) |
| Breaking change (skill renamed/removed) | major (`1.2.0` → `2.0.0`) |

### 3. Commit and push

```bash
git add plugins/kf/
git commit -m "feat: <description of change> (kf v1.2.0)"
git push
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

This always pulls the latest commit from GitHub regardless of version. Use this during development; bump the version for deliberate releases.

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

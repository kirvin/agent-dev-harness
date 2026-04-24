# Design Skills

> **Prerequisite:** These skills are provided by the `kf` plugin from the `claude-config`
> marketplace. They must be installed before this rule has any effect:
> ```
> claude plugin marketplace add github:kirvin/claude-config
> claude plugin install kf@claude-config --scope project
> ```
> Alternatively, run `./scripts/setup.sh` from the claude-config repo.

When working on UI, reviewing design/UX, or establishing design guidelines,
evaluate and activate relevant design skills BEFORE implementing or advising.

## Skill Selection

| Task | Skills to activate |
|------|--------------------|
| Reviewing what design/UX guidelines to establish | `stitch-design-taste`, `ui-ux-pro-max` |
| UX review: critiquing flows, patterns, or information architecture | `ui-ux-pro-max` |
| Building or redesigning a page, screen, or component | `frontend-design`, `design-taste-frontend` |
| UX decisions: layout, color, typography, spacing | `ui-ux-pro-max` |
| Targeting premium / polished visual output | `high-end-visual-design` |
| Auditing or upgrading existing UI quality | `redesign-existing-projects` |
| Clean editorial / minimalist aesthetic requested | `minimalist-ui` |
| Raw mechanical / brutalist aesthetic requested | `industrial-brutalist-ui` |
| Generating a design system or DESIGN.md | `stitch-design-taste` |
| Animations, transitions, springs, gestures, drag, scroll effects | `ui-animation` |
| Generating large components where output may truncate | `full-output-enforcement` |
| Starting from a Figma URL | `figma-to-spec`, `frontend-design`, `design-taste-frontend` |

## Activation Rule

When any row above matches, call `Skill(<skill-name>)` for EACH relevant skill
before writing code or design advice — the same as the global mandatory sequence.
Multiple skills may apply; activate all that match.

`frontend-design` + `design-taste-frontend` are the baseline pair for any
non-trivial UI work. Default to both unless the task is clearly a minor tweak.

When a Figma URL is present, always load `kf:figma-to-spec` first to convert
the design into a structured spec before activating any build skills.

# Design Skills

When working on frontend UI, components, pages, or visual design, evaluate and activate relevant design skills before implementing.

## Skill Selection

| Task | Skills to activate |
|------|--------------------|
| Building or redesigning a page, screen, or component | `frontend-design`, `design-taste-frontend` |
| UX decisions: layout, color, typography, spacing | `ui-ux-pro-max` |
| Targeting premium / polished visual output | `high-end-visual-design` |
| Auditing or upgrading existing UI quality | `redesign-existing-projects` |
| Clean editorial / minimalist aesthetic requested | `minimalist-ui` |
| Raw mechanical / brutalist aesthetic requested | `industrial-brutalist-ui` |
| Generating a design system or DESIGN.md | `stitch-design-taste` |
| Animations, transitions, springs, gestures, drag, scroll effects | `ui-animation` |
| Generating large components where output may truncate | `full-output-enforcement` |

## Activation Rule

When any row above matches, call `Skill(<skill-name>)` before writing any code — the same as the global mandatory sequence. Multiple skills may apply; activate all that match.

`frontend-design` + `design-taste-frontend` are the baseline pair for any non-trivial UI work in this app. Default to both unless the task is clearly a minor tweak.

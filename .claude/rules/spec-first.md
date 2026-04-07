# Spec-First Development

All non-trivial features and new projects follow a spec-first approach. Use `Skill(spec-first)` to load the full methodology.

## When to Activate

| Situation | Action |
|-----------|--------|
| Starting a new project | Load `Skill(spec-first)` and follow the full sequence |
| Scoping a new feature | Load `Skill(spec-first)` before writing any code |
| Writing an ADR, EARS file, or feature spec | Load `Skill(spec-first)` for format and templates |
| An open question needs classification | Load `Skill(spec-first)` to map it to the right layer |
| Asked "how should we build X?" | Write an ADR — not a chat message |

## When It Does NOT Apply

Bug fixes that restore documented behavior, CI tweaks, test isolation improvements, dependency upgrades with no behavior change.

## Layer Quick Reference

| Layer | Document | Written as |
|-------|----------|------------|
| Scope & priorities | `docs/requirements.md` | MoSCoW list, user stories |
| System invariants | `docs/ears/*.md` | SHALL/SHALL NOT sentences |
| Technology decisions | `docs/adr/ADR-NNN-*.md` | Decision + alternatives + consequences |
| System design | `docs/architecture.md` | Mermaid diagrams + prose |
| Acceptance criteria | `docs/features/**/*.feature` | Gherkin Given/When/Then |
| Implementation | `plans/YYYY-MM-DD-*/` | Phased tasks with verify steps |

Full format guides, templates, and examples: `Skill(spec-first)`.

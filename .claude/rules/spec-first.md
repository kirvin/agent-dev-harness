# Spec-First Development

All non-trivial features and new projects follow a spec-first approach. Use `Skill(kf:spec-first)` to load the full methodology.

## When to Activate

| Situation | Action |
|-----------|--------|
| Starting a new project | Load `Skill(kf:spec-first)` and follow the full sequence |
| Scoping a new feature | Load `Skill(kf:spec-first)` before writing any code |
| Writing an ADR, EARS file, or feature spec | Load `Skill(kf:spec-first)` for format and templates |
| An open question needs classification | Load `Skill(kf:spec-first)` to map it to the right layer |
| Asked "how should we build X?" | Write an ADR — not a chat message |

## When It Does NOT Apply

Bug fixes that restore documented behavior, CI tweaks, test isolation improvements, dependency upgrades with no behavior change.

## Open Question Rule (applies to all requirements work)

Every open question in a requirements doc must be categorized before the session ends — whether you wrote the doc or are updating it.

| Mark | Meaning | Action required |
|------|---------|-----------------|
| ✅ | Decided inline | Update the doc — no issue needed |
| ⏳ | Deferred to a named phase | Note the gate in the doc — no issue yet |
| *(none)* | Decision-blocking | `bd create` immediately |

An open question with no category is a dead end. It will never appear in `bd ready`.

**Also:** any requirements doc with a phased delivery plan (Phase A / B / C) needs a Phase A planning issue in beads before the session ends. A plan with no issues is equally invisible.

## Layer Quick Reference

| Layer | Document | Written as |
|-------|----------|------------|
| Scope & priorities | `docs/requirements.md` | MoSCoW list, user stories |
| System invariants | `docs/ears/*.md` | SHALL/SHALL NOT sentences |
| Technology decisions | `docs/adr/ADR-NNN-*.md` | Decision + alternatives + consequences |
| System design | `docs/architecture.md` | Mermaid diagrams + prose |
| Acceptance criteria | `docs/features/**/*.feature` | Gherkin Given/When/Then |
| Implementation | beads — an epic + one issue per phase | Phased tasks with verify steps, in issue descriptions |

The implementation layer is the one that does **not** get a document. Phased
tasks go straight into beads; see `.claude/rules/planning.md` for why and for
where each part of a plan belongs. The layers above it are durable specs that
describe the system; a plan describes work in flight, and work in flight is what
goes stale.

Full format guides, templates, and examples: `Skill(kf:spec-first)`.

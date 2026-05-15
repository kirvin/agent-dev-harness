# Architecture Decision Records

Architectural decisions for this project are documented as ADRs in `docs/adr/`. Do not create ad-hoc decision documents elsewhere.

**Before writing any documentation about a technology choice, data model decision, or API design decision: read `docs/adr/README.md` first.** Check whether the decision is already recorded, and use the existing ADR format and numbering sequence for anything new.

## When to write an ADR

Write an ADR when you are making or recording a decision that:
- Chooses between two or more meaningful alternatives (tech stack, data model shape, API design pattern)
- Has non-obvious trade-offs that a future contributor would need to understand
- Would be hard to reverse or costly to change later

Do NOT write an ADR for:
- Implementation details derivable from reading the code (e.g., which z-index a UI element uses)
- Bug fixes or behavior corrections
- Tooling conventions already captured in other rule files

## Format

```markdown
# ADR-NNN: Title

**Status:** Accepted | Superseded by ADR-NNN | Deprecated  
**Date:** YYYY-MM-DD  
**Supersedes:** ADR-NNN (if applicable)

## Context
Why this decision was needed. What alternatives were considered.

## Decision
What was decided, in one or two sentences.

## Consequences
**Positive:** what gets better  
**Negative:** what gets worse or what constraints this creates
```

File name: `ADR-NNN-short-slug.md` (next number from `docs/adr/README.md`).

## After writing an ADR

1. Add a row to the table in `docs/adr/README.md`
2. Include both files in the same commit as the work that motivated the decision

## Session close checklist

When closing an issue that involved a significant architectural choice:

```
[ ] Is this decision already in docs/adr/?
    - Yes: no action needed
    - No: write an ADR before committing
```

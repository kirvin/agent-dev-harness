# Implementation Plan Structure

Plans translate finalized specs into executable work. No plan is written until requirements, EARS constraints, and ADRs are decided.

## File Layout

```
plans/
  YYYY-MM-DD-[feature]/
    README.md             # Overview: goal, tech stack, phase summary, dependencies
    phase-1-[name].md     # One file per phase
    phase-2-[name].md
    ...
```

Use a folder when a plan has more than one phase. Single-phase work goes in one file directly under `plans/`.

## Phase Rules

Each phase must deliver something demoable. "Built the database layer" is not demoable. "Can capture a photo and see it in the capture history" is.

| Good phase | Bad phase |
|-----------|-----------|
| Delivers working end-to-end slice | Delivers infrastructure with no user-visible outcome |
| Can be shown to someone unfamiliar with the codebase | Requires explanation of why this is useful |
| Leaves the system in a better state if work stops here | Leaves dangling dependencies if stopped early |

## README Template

```markdown
# [Feature] Implementation Plan

> **Status:** DRAFT | APPROVED | IN_PROGRESS | COMPLETED
> **Date:** YYYY-MM-DD

## Goal

[One paragraph: what the system does after all phases are complete that it
couldn't do before. Write from the user's perspective.]

## Spec References

- Requirements: `docs/requirements.md` §[section]
- Architecture: `docs/architecture.md` §[section]
- ADRs: ADR-NNN, ADR-NNN
- EARS: `docs/ears/[file].md`

## Tech Stack

| Layer | Technology | ADR |
|-------|-----------|-----|
| [Layer] | [Technology] | ADR-NNN |

## Phases

| Phase | Delivers | Depends on |
|-------|---------|------------|
| 1 — [name] | [demoable outcome] | — |
| 2 — [name] | [demoable outcome] | Phase 1 |
| 3 — [name] | [demoable outcome] | Phase 2 |

## Beads Issues

[Link phase tasks to Beads issue IDs after creating them]
```

## Phase Task Template

```markdown
# Phase N: [Name]

> **Status:** DRAFT | IN_PROGRESS | COMPLETED
> **Depends on:** Phase N-1

## Goal

[What this phase delivers. One sentence.]

## Context

Read before starting:
- `docs/[relevant spec file]`
- `src/[relevant dir]/`

## Tasks

### Task N.1: [Task Name]

**Context:** `[file or directory to read first]`

**Steps:**
1. [ ] [Concrete action with explicit file path]
2. [ ] [Next action]
3. [ ] Add tests in `[test file path]`

**Verify:** `[command that proves this task is complete]`

---

### Task N.2: [Task Name]

...

## Phase Verification

[Command or checklist that proves the phase is demo-ready]
```

## Sizing

A task should take one agent one focused session to complete. If a task requires reading more than 5–6 files before starting, it's probably two tasks.

Group tasks that touch the same files. Agents that share context work faster and make fewer mistakes.

## Beads Integration

After writing a plan, create Beads issues immediately — one per phase. Wire dependencies with `bd dep add`. Do not start implementation without issues tracking the work.

```bash
bd create --title="Phase 1: [name]" --type=task --priority=2
bd create --title="Phase 2: [name]" --type=task --priority=2
bd dep add [phase-2-id] [phase-1-id]
```

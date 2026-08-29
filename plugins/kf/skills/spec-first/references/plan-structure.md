# Implementation Plan Structure

Plans translate finalized specs into executable work. No plan is written until requirements, EARS constraints, and ADRs are decided.

**A plan is a set of beads issues, not a document.** Layers 1–5 of the spec model are durable documents that describe the system. A plan describes work in flight, and work in flight is what goes stale — a plan doc and a set of issues are two copies of the same structure, and the doc is the copy nobody updates. Within days it is a false trail that reads as current.

So everything below describes how to shape the work, and where each part of it lands in beads. See `.claude/rules/planning.md` for the rule.

## Layout

```
epic                        # the whole feature
  └── one issue per phase   # chained with bd dep add
```

Use an epic when a plan has more than one phase. Single-phase work is one issue, no epic.

## Phase Rules

Each phase must deliver something demoable. "Built the database layer" is not demoable. "Can capture a photo and see it in the capture history" is.

| Good phase | Bad phase |
|-----------|-----------|
| Delivers working end-to-end slice | Delivers infrastructure with no user-visible outcome |
| Can be shown to someone unfamiliar with the codebase | Requires explanation of why this is useful |
| Leaves the system in a better state if work stops here | Leaves dangling dependencies if stopped early |

## Epic Description Template

The epic carries everything that is true across phases. Write it with `--body-file`; it will be long, and that is correct.

```markdown
[One paragraph: what the system does after all phases are complete that it
couldn't do before. Write from the user's perspective.]

PROBLEM.  [What is broken or missing now, specifically enough that someone
          unfamiliar understands why this work exists.]
GOAL.     [The end state, described as experience rather than implementation.]
SCOPE.    [In and out. Explicit boundaries prevent scope creep.]

SPEC REFERENCES
  Requirements: docs/requirements.md §[section]
  Architecture: docs/architecture.md §[section]
  ADRs:         ADR-NNN, ADR-NNN
  EARS:         docs/ears/[file].md

ARCHITECTURE
  [Diagram or prose. What the pieces are and why the seams sit where they do.]

INVARIANTS
  [Numbered. For each, name what enforces it — a test, a CI check, a schema
  constraint. An invariant with no enforcement is a comment.]

DECISIONS TAKEN
  [Each with its rationale. This is what stops phase 4 relitigating phase 1.]

TECH STACK
  | Layer | Technology | ADR |

PHASE MAP
  0 [name]  <id>
  1 [name]  <id>
  ...
```

Acceptance criteria for the epic go in `--acceptance`: the handful of statements that, taken together, mean the feature is done.

## Phase Issue Description Template

One issue per phase. The description carries the entire breakdown — a fresh contributor should execute from it without opening anything else.

```markdown
[What this phase delivers. One or two sentences.]

Context to read first:
  docs/[relevant spec file]
  src/[relevant dir]/
  bd show <epic-id>            # invariants and decisions

---
TASK N.1 -- [Task Name]

[Why this task is shaped this way, when that is not obvious. A step list with
no rationale gets followed literally and wrongly.]

1. [Concrete action with explicit file path]
2. [Next action]
3. Add tests in [test file path]

Verify: [command that proves this task is complete]

---
TASK N.2 -- [Task Name]

...
```

Phase verification — the command or checklist proving the phase is demo-ready — goes in `--acceptance`, not in the description.

## What goes where

| Part | Field |
|---|---|
| What the phase is, every task, every step | `--description` (`--body-file` for anything long) |
| How you know the phase is done | `--acceptance` |
| Sequencing between phases | `bd dep add <later> <earlier>` |
| Why the framing changed mid-flight | `bd note` (append-only) |

Put the implementation detail in the description, not the `design` field. Both render in `bd show`, but the description is the one place a fresh contributor is expected to read, and two locations is how things get missed.

## Sizing

A task should take one agent one focused session to complete. If a task requires reading more than 5–6 files before starting, it's probably two tasks.

Group tasks that touch the same files. Agents that share context work faster and make fewer mistakes.

## Wiring

```bash
bd create "Epic: [feature]" -t epic -p 1 --body-file epic.md --acceptance "..."
bd create "Phase 1: [name]" -t task -p 2 --body-file phase-1.md --acceptance "..."
bd create "Phase 2: [name]" -t task -p 2 --body-file phase-2.md --acceptance "..."

bd update <phase-1-id> --parent <epic-id>
bd update <phase-2-id> --parent <epic-id>
bd dep add <phase-2-id> <phase-1-id>      # phase 2 depends on phase 1

bd dep cycles                              # graph is sane
bd ready                                   # the right thing surfaces first
```

Do not start implementation without issues tracking the work.

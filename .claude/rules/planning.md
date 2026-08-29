# Planning → Beads

See `.claude/rules/beads-workflow.md` for the philosophy: structure (deps, epics, descriptions) belongs in beads; prose docs and memory files are not substitutes for `bd ready`.

## Session start

Run `bd ready` to see unblocked issues. The dep graph is the source of truth for "what's next" — do not consult plan docs or memory files to override it. If `bd ready` shows the wrong thing, the fix is in beads (add a dep, edit a description), not in a markdown note.

---

## Plans live in beads, not in repo markdown

Do not create a plan document under `plans/` for new work. A plan doc and a set of issues are two copies of the same structure, and the doc is the copy nobody updates — it goes stale within days and becomes a false trail that reads as current.

This overrides `ce:writing-plans`, which says to save to `plans/YYYY-MM-DD-*.md`. Use that skill for its task-shaping guidance — sizing, grouping, verification per task — and write the output straight into beads.

File the issues **before ending the session**. Do not wait for the user to ask.

## Where a plan's parts go

| Part of the plan | Goes in |
|---|---|
| Problem, goal, scope, architecture, invariants, decisions | Epic **description** |
| One phase / major work unit | One issue, `bd create` |
| What the phase is and every task in it, with steps | Issue **description** — the whole thing, not a pointer |
| How you know the phase is done | Issue **acceptance** (`--acceptance`) |
| Sequencing between phases | `bd dep add <later> <earlier>` — **the deps are the plan** |
| Why the framing changed mid-flight | Issue **notes** (append-only) |

Put the implementation detail in the **description**, not the `design` field. Both render in `bd show`, but `beads-workflow.md` makes the description the one place a fresh contributor is expected to read. Two locations is how things get missed.

Descriptions can be long — a phase issue carrying its full task breakdown, a schema, or an algorithm spec is working as intended. Use `--body-file` for anything past a paragraph:

```bash
bd update <id> --body-file /path/to/content.md --acceptance "..."
```

## Required steps

1. One issue per phase or major work unit
2. Wire the dependency chain with `bd dep add`
3. Parent the phases to an epic with `bd update <id> --parent <epic>`
4. `bd dep cycles` to confirm the graph is sane
5. `bd ready` to confirm the right thing surfaces first

## Issue content

- **Title**: Phase name + brief description (e.g., "Phase 1: Polymorphic comments data model & migration")
- **Description**: the whole phase — what it accomplishes and every task in it, with steps. A fresh contributor should be able to execute from the description alone.
- **Type**: `task` for implementation phases, `epic` for the parent
- **Priority**: Match the feature's priority (default P2 for new features)

## Dependency wiring

Phases should block each other in sequence:
```bash
bd dep add <phase-2-id> <phase-1-id>   # phase 2 depends on phase 1
bd dep add <phase-3-id> <phase-2-id>   # phase 3 depends on phase 2
```

## Do not block design issues on infrastructure

A design-and-plan issue should stay in `bd ready` even when the thing it plans cannot yet be built or deployed. Blocking it hides it. Put the sequencing constraint in the description and wire the dep onto the *implementation* issue instead.

## Dependencies across two beads databases

When a project spans repos with separate trackers (an app repo and a deployment repo, say), `bd dep add` cannot express an edge between them. Write the constraint into the dependent issue's description, naming the other tracker's issue id and the command to check it:

```
CROSS-TRACKER DEPENDENCY (beads cannot express this, so it is written down):
this issue additionally requires <id> to be complete.
Check `bd -C /path/to/other/repo ready` before starting.
```

This is weaker than a wired dep and is the honest price of splitting a project across trackers. Prefer one tracker when the choice is open.

## When the plan has a single unit of work

If the plan is a single task (no phases), create one beads issue and mark it `in_progress` immediately if implementation is starting in the same session.

## Existing plan docs

Leave them where they are. Some are referenced by other rules and by open epics, and this standard applies to new work — it is not a licence to delete history. When you next touch one of those epics, consider folding its plan into the issues and retiring the doc then.

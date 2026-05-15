# Beads Workflow — Default to Structure, Not Prose

`bd` is the issue tracker. The recurring failure mode is **describing structure in prose** (memory files, plan docs, "do A then B then C") instead of **encoding it in beads** (deps, epics, descriptions). Prose drifts; `bd ready` is enforced.

## Single source of truth

`bd ready` is the canonical "what should I work on next." If it shows the wrong thing, fix it in beads — add a dep, edit a description. Never override it with a memory file or plan doc.

## Where does this fact belong?

| Fact | Belongs in | Smell-check phrase that means "use this" |
|------|------------|------------------------------------------|
| Sequencing across issues ("A before B", "don't pick up X yet") | `bd dep add <later> <earlier>` | "do these in this order", "don't start X yet" |
| N issues form a logical unit | Parent `feature` issue, children depend on it | "these three are related", "here's the queue for next session" |
| Implementation outline / schema refs / acceptance criteria | Issue **description** (edit freely) | "here's how to do this issue" |
| Mid-flight correction or rationale change | Issue **notes** (append-only) | "the framing was wrong, here's why we pivoted" |
| Stable codebase/env fact not derivable from code | Memory file (`project_*.md`) | port numbers, image versions, workspace gotchas |
| Cross-session insight that doesn't fit one issue | `bd remember "<insight>"` | a heuristic, a watch-out, a non-obvious gotcha |
| User preferences / collaboration style | Memory file (`feedback_*.md`) | "I prefer...", "always do..." |

Rule of thumb: if the fact is still true in a fresh session with no context, it goes in beads (description, dep, or `bd remember`). If it's only about *this session's working state*, it goes nowhere.

## Description vs notes

- **Description** = canonical "what this issue is and how to do it." Edit it as understanding sharpens (`bd update <id> --description "..."`). A fresh contributor should read only the description and know what to do.
- **Notes** = append-only history. Corrections, rationale changes, discoveries. Don't stack handoff context here — after three "actually, the previous note was wrong" rounds, notes become geological strata. Move stable info into the description.

## Stale-issue cleanup is part of the work

When an issue's framing turns out wrong, edit the description to reflect reality. If the issue is no longer the right unit, close it with a reason or merge it. Do not leave outdated framing for the next session to re-discover.

## Compatible rules

- `.claude/rules/planning.md` — after writing a plan, file beads issues and wire phase deps. The deps **are** the plan.
- `.claude/rules/beads-github.md` — `make bd-close` for GitHub-linked issues.

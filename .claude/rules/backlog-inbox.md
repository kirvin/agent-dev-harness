# Backlog Inbox Harvest

`docs/TODO.md` is a **git-ignored scratchpad** where ideas get jotted under `## Inbox` with no
ceremony. It is not the backlog — beads is (`bd ready`). **Harvest** bridges the two: turn each
Inbox item into a beads issue, then move it to `## Filed` tagged with its id (or delete it).
Because the file is git-ignored, an un-harvested item is unshared and unbacked-up until it
becomes an issue, so harvest promptly.

This rule is a no-op in a project that has no `docs/TODO.md` (or no `## Inbox`) — adopt the file
to opt in.

## When to harvest

| Trigger | Action |
|---------|--------|
| **Session start** | If `docs/TODO.md` exists and `## Inbox` holds items, harvest them. This is the inbound half of `.claude/rules/planning.md`'s session-start `bd ready` (capture → beads); that rule is the outbound half (beads → what to work on). |
| **On request** | "triage the backlog", "harvest the TODO", "process the inbox", "triage docs/TODO.md" |

A missing or empty `## Inbox` is a no-op. Do not announce it.

## Steps

For each non-blank `- [ ]` line under `## Inbox`:

1. **Decide it is worth tracking.** If it is a duplicate, already done, or not real, delete the
   line and move on. Do not create noise issues.
2. **`bd create`** it: `bd create --title="..." --type=<task|feature|bug> --priority=<0-3>` with a
   description that captures the item's intent — expand terse notes so a fresh contributor
   understands it. Sequencing, deps, and what-belongs-where follow `.claude/rules/beads-workflow.md`.
3. **Move the line to `## Filed`**, appended with its id: `` - [x] <text> — `<issue-id>` ``.

The file is git-ignored, so **do not commit it** — the edit is local bookkeeping; the durable
record is the beads issue.

## Notes

- Only `## Inbox` is harvested. Never create issues from `## Filed` (already harvested).
- Preserve the author's wording in the Filed line; expand it in the beads description, not the line.
- One Inbox line may become several issues, or several lines one issue — use judgment and note any
  fold in the Filed line (e.g. "folded both search items").

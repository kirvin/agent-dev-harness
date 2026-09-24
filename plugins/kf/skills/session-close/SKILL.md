---
name: session-close
description: End-of-session protocol. Saves in-progress context to beads issues, pushes all work to remote, and prints a handoff block for resuming the next session. Invoke before /clear or exiting Claude Code.
---

# Session Close Protocol

Run this when the user wants to end the session, clear context, or hand off to
a future session. It does three things in order:

1. **Persist state** — save any session context into beads issue notes
2. **Push everything** — git push, plus beads via `beads-sync.sh` (honours `.claude/kf.json`)
3. **Print handoff block** — concise instructions for the next session

---

## Step 1 — Gather state

Run these in parallel:

```bash
bd list --status=in_progress
bd ready
git status
git log --oneline -5
```

---

## Step 2 — Update in-progress issues

For each in-progress issue, append a `## Session State` block to its notes
capturing where things stand RIGHT NOW. Focus on what a future session needs
to pick up without re-reading this conversation.

Write the block as if briefing a colleague who hasn't seen this conversation:

```
## Session State — <date>
- Done: <what was completed or decided in this session>
- Left off: <exact state — file modified, test failing, deploy pending, etc.>
- Next action: <the single most important next step>
- Context: <anything non-obvious that future-Claude needs to know>
```

Only include sections that have content. Keep it under 6 bullets total.

```bash
bd update <id> --notes "## Session State — $(date +%Y-%m-%d)
- Done: ...
- Left off: ...
- Next action: ..."
```

For open issues that were **discussed but not started**, add a short note if
the conversation surfaced a decision or constraint worth saving:

```bash
bd update <id> --notes "Context from session $(date +%Y-%m-%d): ..."
```

---

## Step 3 — Push all work

Never run `bd dolt push` directly. The beads step goes through `beads-sync.sh`,
which sits in this skill's base directory (shown when the skill loads):

```bash
git pull --rebase
bash <skill base directory>/beads-sync.sh
git push
git status   # must show "up to date with origin"
```

`beads-sync.sh` runs `bd dolt push` by default. If the project commits
`.claude/kf.json` containing `{"beads": {"remotePush": false}}`, it never
pushes. Instead it checks read-only that no Dolt remote or backup destination
points off-machine, then runs a local `bd backup sync`.

If `beads-sync.sh` exits non-zero, stop and show the user its message. Do not
work around it: do not push to test the remote, and do not edit remotes or the
config unless the user asks. `git push` still runs, because code and beads data
are separate.

If `git push` fails, resolve and retry before continuing.

---

## Step 4 — Print handoff block

Output this block in the chat so the user can see it or copy it:

```
## Session Handoff — <date>

**Branch:** <current branch>
**Last commit:** <short hash> — <commit subject>

### Completed this session
- <issue id>: <one-line description of what was done>
- ...

### In progress (pick up here)
- <issue id>: <Left off: ...> / <Next action: ...>
- ...

### Recommended next
- <issue id from bd ready>: <title>

### Context for next session
- <anything critical: pending deploys, placeholder values, env state, decisions made>
```

Keep each line to one sentence. The goal is a future session that can run
`bd show <id>` and start immediately — not a summary of this conversation.

---

## What counts as "relevant context to save"

Save to beads notes when the session produced:
- A decision that isn't obvious from the code (e.g., "chose task body over child page")
- A half-finished implementation with a specific next step
- A discovered constraint or blocker
- An env dependency that isn't wired yet (e.g., API key placeholder)
- A test that was left red intentionally

Do NOT save:
- Information already in the code or commit history
- General conversation or explanations
- Things already in CLAUDE.md or SKILL.md files

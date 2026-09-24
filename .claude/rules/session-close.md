# Session Close

When the user wants to end the session, clear context, or hand off work, load
the `session-close` project skill.

## Trigger phrases

Load `session-close` when the user says things like:
- "wrap up", "let's wrap", "closing out"
- "I'm done for now", "that's it for today", "stopping here"
- "save context", "save session", "save my place"
- "generate handoff", "handoff notes", "next session instructions"
- "before I clear", "before I /clear", "before I exit"
- "session close", "/session-close"

## What the skill does

1. Updates in-progress beads issues with a `## Session State` block
2. Pushes git, and pushes beads via its `beads-sync.sh` (which honours the opt-out below)
3. Prints a handoff block with branch state, in-progress issues, and next recommended action

The handoff block is what makes the next session productive without re-reading
this conversation.

## Keeping beads data on this machine

Some projects must never push beads data (for example, issues that hold private
financial or personal details). To opt out, commit `.claude/kf.json`:

```json
{"beads": {"remotePush": false}}
```

Then configure a local backup once: `bd backup init <local path outside the repo>`.

With the opt-out set, session-close never runs `bd dolt push`. It refuses to
continue if any Dolt remote or the backup destination points off-machine, and
otherwise runs `bd backup sync`. Code still goes out with `git push`.

Put overrides in `.claude/kf.json`, not in this file. `install-to-project.sh --force`
overwrites the rules in `.claude/rules/`, but it never writes `kf.json`.

Unsetting `sync.remote` is not an opt-out. bd falls back to the git origin, and
the Dolt database keeps its own `origin` remote. Check with
`bd dolt remote list`, never by pushing.

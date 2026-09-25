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
financial or personal details). To opt out:

1. Commit `.claude/kf.json` next to `.beads/` (or at the git root):
   ```json
   {"beads": {"remotePush": false}}
   ```
2. Turn on bd's own kill switch and commit `.beads/config.yaml`:
   `bd config set no-push true`. After this, a stray `bd dolt push` prints
   "skipping push" and sends nothing. `no-push` does NOT stop auto-push, so
   leave `dolt.auto-push` off.
3. Configure a local backup once: `bd backup init <path>`. The path must be
   outside the repo and not in a cloud-synced or network folder. That rules out
   Dropbox, iCloud, Google Drive, OneDrive, Box and a NAS mount. It also rules
   out `~/Desktop` and `~/Documents`, which sync to iCloud on many Macs.

With the opt-out set, session-close never runs `bd dolt push`. It refuses to
continue if any of these is true:
- `no-push` is off
- `dolt.auto-push`, `export.auto`, `export.git-add` or `events-export` is on
- a Dolt remote or the backup destination points off-machine
- a local remote or the backup is inside the repo or in a cloud-synced folder
- `kf.json` has any key or value it does not recognise

Otherwise it runs `bd backup sync`. Code still goes out with `git push`.

Put overrides in `.claude/kf.json`, not in this file. `install-to-project.sh --force`
overwrites the rules in `.claude/rules/`, but it never writes `kf.json`.

Unsetting `sync.remote` is not an opt-out. bd falls back to the git origin, and
the Dolt database keeps its own `origin` remote. Check with
`bd dolt remote list`, never by pushing.

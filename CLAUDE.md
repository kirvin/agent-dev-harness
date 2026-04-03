# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

## Project Documentation

See the following docs for project-specific details:

- `docs/codebase-overview.md` — Architecture, services, data model
- `docs/development.md` — Development commands and common workflows
- `docs/decisions.md` — Architectural decision log

## Issue Tracking (Beads)

This project uses **Beads** (`bd`) for AI-native issue tracking.

```bash
bd ready          # show next issue to work on
bd show <id>      # show issue details
bd update <id>    # update issue status/notes
bd close <id>     # close completed issue
```

Mandatory steps per issue: pick issue → implement → run quality gates → `bd close` → `git push`.

**When the user gives a direct implementation instruction**, always create a beads issue with `bd create` before writing any code. Mark it `in_progress` immediately, then proceed.

# Compact instructions

When using compact, focus on test output and code changes.

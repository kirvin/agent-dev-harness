# Planning → Beads Integration

After writing any implementation plan (using `ce:writing-plans` or manually), immediately create beads issues **before ending the session**. Do not wait for the user to ask.

## Required steps after a plan is written

1. Create one beads issue per phase or major work unit using `bd create`
2. Wire dependencies between phases using `bd dep add`
3. Confirm with `bd list --status=open` that the issues appear correctly

## Issue content

- **Title**: Phase name + brief description (e.g., "Phase 1: Polymorphic comments data model & migration")
- **Description**: What the phase accomplishes + reference to the plan file path
- **Type**: `task` for implementation phases, `feature` for epics
- **Priority**: Match the feature's priority (default P2 for new features)

## Dependency wiring

Phases should block each other in sequence:
```bash
bd dep add <phase-2-id> <phase-1-id>   # phase 2 depends on phase 1
bd dep add <phase-3-id> <phase-2-id>   # phase 3 depends on phase 2
```

## When the plan has a single unit of work

If the plan is a single task (no phases), create one beads issue and mark it `in_progress` immediately if implementation is starting in the same session.

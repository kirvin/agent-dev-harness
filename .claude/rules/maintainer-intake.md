# Maintainer Intake

When a developer pastes an error log, error message, or bug description directly into
conversation — before attempting any fix — load `intake-report` to create a proper
beads issue first.

## Trigger conditions

Load `Skill(kf:intake-report)` when:
- A developer pastes an error log or stack trace in conversation and asks for help
- A developer describes a bug: "X is broken", "X stopped working", "X is behaving wrong"
- A bug is reported verbally and no beads issue exists yet for it

## What the skill does

1. Extracts structured report details from the pasted content or description
2. Creates a beads issue with reproduction steps and severity
3. Claims the issue and starts the fix
4. Ensures the fix commit references the beads ID

## Why this matters

Jumping straight to debugging leaves no traceable record. The intake step takes 30 seconds
and creates the link between the report, the fix, and `git log` that makes future debugging
and retros possible.

## When NOT to trigger

- When a beads issue already exists for the bug being fixed
- When the user is describing a bug in their own code (not the toolkit)
- When the conversation is clearly already in the middle of an active fix session

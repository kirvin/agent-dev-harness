---
name: intake-report
description: Maintainer intake protocol for bug reports received directly in conversation. Extracts structured details from a pasted error log or verbal description, creates a beads issue, then begins the fix. Prevents the common failure mode of starting a fix without a traceable issue.
---

# Intake Report

Load this skill when a developer pastes an error log, describes a bug they hit, or reports
unexpected behavior directly in a conversation — before starting any debugging or fix work.

## Why intake first

Jumping straight to debugging leaves no traceable record of what was reported, what was
tried, or what decision was made. The beads issue is the anchor that connects the report
to the fix and to `git log`.

## Step 1 — Extract the report

From what the developer said or pasted, identify:

| Field | What to find |
|-------|-------------|
| **Affected component** | Which skill, rule, script, or workflow behavior |
| **Reported behavior** | What they observed (error message, wrong output, missing trigger) |
| **Expected behavior** | What should have happened |
| **Reproduction** | What they did: phrase used, context, project type |
| **Severity** | Is this blocking their work, or cosmetic? |
| **Reporter** | Who reported it (if known) |

If any field is unclear, ask one targeted question before proceeding. Don't ask for all
fields at once if the report already makes most of them obvious.

## Step 2 — Create a beads issue

```bash
bd create \
  --title="[Bug] <component>: <one-line description of observed behavior>" \
  --description="## Report
<Reported behavior — quote the developer's words where possible>

## Reproduction
<What the developer did or said>

## Expected behavior
<What should have happened>

## Notes
Reporter: <name or 'anonymous'>
Severity: <blocking / high / low>
Received: $(date +%Y-%m-%d)" \
  --type=bug \
  --priority=<1 if blocking, 2 if high, 3 if low>
```

Show the created issue ID before proceeding.

## Step 3 — Claim and start

```bash
bd update <id> --claim
```

Now begin the fix. Reference the issue ID in all commits:

```
fix: <description>

Beads: <id>
Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
```

## Step 4 — Close with findings

When the fix is done, load `kf:task-completion` for the standard verification + mini-retro
protocol before closing the beads issue.

If the bug was reported via a GitHub issue in the toolkit repo, use `bd-close.sh` so both
are closed atomically:

```bash
./scripts/bd-close.sh <id> --reason="Fixed in <commit-sha>"
```

## Intake checklist

```
[ ] Affected component identified
[ ] Reproduction steps captured (even if fuzzy)
[ ] Beads issue created with structured description
[ ] Issue claimed and marked in_progress
[ ] Fix commit references the beads ID
```

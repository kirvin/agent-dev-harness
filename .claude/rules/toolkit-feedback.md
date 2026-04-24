# Toolkit Feedback

When a developer reports a problem with the toolkit itself — a skill that doesn't work,
a rule that doesn't trigger, or a workflow that's confusing — load the `report-toolkit-issue`
skill to capture and file it properly.

## Trigger phrases

Load `Skill(kf:report-toolkit-issue)` when the user says things like:
- "Report a bug" / "File a bug" / "This is a bug in the toolkit"
- "This skill is broken" / "This rule isn't working" / "This isn't triggering"
- "File a feature request" / "Suggest an improvement" / "The toolkit should..."
- "Something is wrong with [skill/rule name]"
- "Can you report this to the toolkit maintainer?"

## What the skill does

1. Identifies the affected component (skill, rule, or script)
2. Collects reproduction steps from context or by asking
3. Drafts a GitHub issue for your review before filing
4. Creates the issue in `kirvin/claude-config` via `gh issue create`
5. Optionally creates a linked beads issue for local tracking

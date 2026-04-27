---
name: report-toolkit-issue
description: File a GitHub issue in the agent-dev-harness repo directly from conversation. Use when a developer reports a bug in a skill or rule, requests a new feature in the toolkit, or wants to flag a workflow problem. Collects structured details and creates the issue via gh CLI.
---

# Report Toolkit Issue

Use this skill when a developer says something like:
- "Report a bug" / "File a bug"
- "This skill is broken" / "This rule isn't triggering"
- "File a feature request" / "Suggest an improvement to the toolkit"
- "The toolkit is doing something wrong"

## Step 1 — Determine issue type

Ask (or infer from context):

- **Bug**: something that worked before is broken, or behavior differs from what the skill/rule documents
- **Feature request**: new capability, skill, or rule they want added
- **Improvement**: existing skill or rule that works but could be better

## Step 2 — Collect details

Gather the minimum needed. For a **bug**:

```
- Which skill or rule is affected? (e.g., kf:session-close, .claude/rules/tdd.md)
- What did you expect to happen?
- What actually happened?
- Reproduction: what did you say or do that triggered it?
- Any error output or unexpected behavior you can paste?
```

For a **feature request or improvement**:

```
- What capability is missing or inadequate?
- What problem would it solve?
- Any specific scenario where this would help?
```

Keep the intake conversational — pull from what the user already said rather than asking for all fields upfront if the context makes most of them clear.

## Step 3 — Draft the issue

Format the issue before creating it so the user can review or correct:

```markdown
**Title:** <concise, specific: "kf:session-close doesn't push beads when git is clean">

**Body:**
## Summary
<1–2 sentence description of the problem or request>

## Details
<for bugs: steps to reproduce, expected vs actual, error output>
<for features: use case, what it solves, any constraints>

## Environment
<Claude Code version if known, which project this happened in>
```

Show this to the user and ask: "Does this look right? I'll create the issue once you confirm."

## Step 4 — Create the issue

```bash
gh issue create \
  --repo kirvin/agent-dev-harness \
  --title "<title>" \
  --body "<body>" \
  --label "<bug|enhancement>"
```

After creating, share the issue URL with the user.

## Step 5 — Optional: create a beads task

If the user is the maintainer and wants to track the fix locally:

```bash
bd create \
  --title="<same title>" \
  --description="<summary>

GitHub: <issue-url>" \
  --type=bug \
  --priority=2
```

This links the beads issue to the GitHub issue so `bd-close.sh` can auto-close it later.

## Notes

- The repo is `kirvin/agent-dev-harness` (previously `claude-config`, previously `agent-dev-plugins`).
- If `gh` is not authenticated, guide the user to run `gh auth login` first.
- If the user is in a project that doesn't have `gh` installed, suggest they open the issue manually and provide the formatted body.

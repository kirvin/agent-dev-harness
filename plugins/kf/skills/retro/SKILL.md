---
name: retro
description: Comprehensive retrospective over a span of work (epic, session, timeframe). Gathers git log and beads closed-issue data, delegates pattern analysis to ce:post-mortem, and converts findings into actionable beads improvement issues. Use when the user asks for a retro, retrospective, or review over multiple tasks.
---

# Comprehensive Retrospective

Run when the user asks for a retro over a span of work. Scope can be an epic,
a session range, a timeframe ("last two weeks"), or a set of issues.

This skill owns the **beads data-gathering layer** and the **issue-creation output**.
Analysis is delegated to `ce:post-mortem`, which provides the root-cause framework,
investigation type references, and action type taxonomy.

## Step 1: Gather data

### Determine the scope

Clarify with the user if not explicit:
- **Epic**: `bd show <epic-id>` to get linked issues, then `bd show` each child
- **Timeframe**: e.g. "last two weeks" → use `git log --since`
- **Session**: recent git log + `bd list --status=closed -n 20`

### Git history

```bash
git log --oneline --since="2 weeks ago"          # timeframe-based
git log --oneline <base>..<head>                  # range-based
git log --oneline --grep="Beads: <id>"            # epic (from commit footers)
```

### Closed beads issues

```bash
bd list --status=closed -n 50    # adjust -n for the scope
```

For each closed issue, run `bd show <id>` and extract:
- Title, type, and description
- Notes — especially `## Lessons Learned` blocks from per-task mini-retros
- Any improvement issues already filed from those retros

**`## Lessons Learned` blocks are the primary signal.** Issues without them still
contribute via git history and description, but they're secondary.

## Step 2: Analyze with ce:post-mortem

Load `ce:post-mortem` and apply its four-step process to the collected data:

1. **Reconstruct** — timeline of the span: what was attempted, what happened, where corrections were needed
2. **Assess execution quality** — efficiency, accuracy, tooling fit, communication, outcome
3. **Identify systemic causes** — for recurring friction, ask "What would have prevented this?"
   Push past symptoms to fixable root causes. Load the matching `ce:post-mortem` reference:

   | Pattern found | Load |
   |---------------|------|
   | Wrong files, bad assumptions, unclear conventions | `references/dx-friction.md` |
   | Docs / READMEs were wrong or incomplete | `references/documentation-gaps.md` |
   | Code was hard to find or understand | `references/architecture-clarity.md` |
   | Bugs pointed to process gaps | `references/bug-prevention.md` |
   | Code diverged from best practice repeatedly | `references/anti-patterns.md` |
   | Skills, hooks, or `.claude/` configs need updating | `references/tooling-improvements.md` |

4. **Propose concrete actions** using `ce:post-mortem`'s action types:
   Documentation update · Skill/config update · New skill/hook · Architecture improvement · Test addition · Codify a win

A finding qualifies for a beads issue when it:
- Recurs across ≥ 2 tasks, **or**
- Caused significant friction in a single task

## Step 3: Create improvement issues

For each qualifying finding, create a beads issue:

```bash
bd create \
  --title="[Improvement] <short title>" \
  --description="Root cause: <systemic issue>. Action: <specific change with file path>." \
  --type=task \
  --priority=3
```

**Target 3–7 improvement issues per retro.** If you have more, group related findings.
Confirm with `bd list --status=open` after creating.

## Step 4: Output retro report

Extend the `ce:post-mortem` output format with a beads issues section:

```markdown
## Retrospective: [Scope] — [Date range]

### Coverage
N commits | M closed issues | [date range]

### Execution Assessment
- **Outcome:** [What was delivered across the span]
- **Efficiency:** [Where did work flow well vs where were the detours?]
- **What worked well:** [Patterns worth repeating]

### Findings

#### Finding 1: [Title]
**Pattern:** [What recurred across tasks]
**Root cause:** [Systemic issue — not just what went wrong]
**Action:** [Specific change with file path]
**Issue filed:** `<bd-id>`

#### Finding 2: ...

### Summary
[2–3 sentences: the most important thing to fix first and why.]
```

## Relationship to per-task mini-retro

The `kf:task-completion` skill writes `## Lessons Learned` blocks into beads issue
notes as each task closes. A span with consistent mini-retros produces much richer signal
here. The two work as a pair: mini-retros surface friction per task; this retro finds
systemic patterns across tasks and converts them into trackable improvement work.

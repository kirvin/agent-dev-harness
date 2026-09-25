# Retrospectives

When the user asks for a "retro", "retrospective", or "review" over a span of work
(epic, session, timeframe, or set of issues), load `Skill(kf:retro)`
(it ships in the kf plugin, not in `.claude/skills/`).

The skill handles:
- Data gathering from `git log` and `bd list --status=closed`
- Pattern analysis across five improvement categories (rules, skills, architecture,
  coding standards, documentation)
- Creating actionable beads improvement issues from findings
- Generating a retro report

## Trigger phrases

Load `kf:retro` when the user says things like:
- "Run a retro on [epic/sprint/last week/last session]"
- "Retrospective on the [X] work"
- "What have we learned from [span of work]?"
- "Review [timeframe] and create improvement tasks"

## Relationship to per-task retro

The `kf:task-completion` skill captures per-task `## Lessons Learned` blocks in
beads issue notes. These blocks are the primary input for the comprehensive retro.
The two work as a pair: mini-retros surface friction per task; this retro finds
systemic patterns across tasks.

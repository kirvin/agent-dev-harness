# Test Failures

No test failure may be deferred, attributed to a prior session, or left in a known-failing state.

## The rule

If `npm test` (or your project's equivalent) shows a failure, that failure must be resolved before the current task is closed — regardless of when or where it was introduced.

**Never say:** "this was already failing before my changes" and move on. That is not a valid reason to leave a failure in place.

## If the fix is non-trivial

Create a beads issue for it immediately, mark it P1 or P2, and block your current work on it:

```bash
bd create --title="Fix <test name>" --type=bug --priority=1
bd dep add <current-issue> <new-issue>
```

Then fix the blocker before closing the current issue.

## Session close checklist

Before closing any issue where code was changed:

```
[ ] All tests pass with 0 failures
[ ] No new "open handles" / "leaked process" warnings introduced
```

## Project-specific baselines

Each project should record its current baseline (test count, known-good state) and treat any regression from that baseline as a blocking defect. Add a `## Baseline` section to this rule when the project's test suite is first declared clean.

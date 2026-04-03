# Requirements Maintenance

The requirements doc lives at `docs/requirements.md`. It is the source of truth for what the product does and is read by new contributors, LLMs working on the codebase, and stakeholders.

**Keep it accurate. Update it when features ship.**

## When to update

Update `docs/requirements.md` when closing a beads issue of type `feature` or `bug` that adds or meaningfully changes user-visible behavior. You do not need to update it for:
- Infrastructure fixes, CI tweaks, test isolation improvements
- Dependency upgrades
- Performance fixes with no behavior change
- Bug fixes that restore documented behavior (not new behavior)

If you're unsure, bias toward updating. A sentence too many is better than stale docs.

## What to update

| Change type | Action |
|-------------|--------|
| New user-facing feature | Add new section (numbered to fit the relevant area) |
| Extension to an existing feature | Add acceptance criteria to the existing section |
| Changed behavior | Update the relevant criteria in place |
| Removed feature | Delete or mark the criteria as removed |

## How to add a section

1. Pick the right parent section (auth, profiles, communities, posts, comments, etc.)
2. Use the lettered-subsection pattern for sub-features: `8.2a`, `8.3b`, etc.
3. Keep the format consistent — use the SHALL/MAY/WHEN pattern from the existing doc
4. Add a user story (`**User Story:** As a...`) only when the feature is user-initiated

## Minimum criteria per section

Write at least one acceptance criterion per meaningful behavior. A criterion should be falsifiable — you should be able to write a test that verifies it or catches a regression if it breaks.

## Session close checklist

When closing a feature issue (`bd close <id>`), add a docs step:

```
[ ] Does docs/requirements.md reflect the new behavior?
    - If yes: no action needed
    - If no: update requirements.md before committing
```

Include the requirements update in the same commit as the implementation, not as a follow-on.

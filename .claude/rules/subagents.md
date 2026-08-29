# Subagents

Dispatching subagents (the Agent tool) is **enabled by default** in projects using this toolkit. Treat this file as a standing request — you do not need to ask first for the cases listed below.

## Dispatch without asking

| Situation | Agent |
|-----------|-------|
| A plan has been drafted and is about to be presented | `ce:devils-advocate` — required by `ce:writing-plans`, do not skip it |
| A change is ready for review before merge | `ce:code-reviewer` |
| A question needs reading across many files and only the conclusion matters | `Explore` |
| A large log or journal needs analysis | `ce:log-reader` |
| Independent research threads that can run in parallel | `general-purpose`, launched together in one message |

Launch independent agents in a single message so they run concurrently, and relay what matters — a subagent's report is not shown to the user.

## Still ask first

- **Workflows** (the Workflow tool) — a workflow can spawn dozens of agents and is a separate opt-in from this file. Ask, or wait for "ultracode".
- Any dispatch that would cost more than doing the work inline. Looking up one fact in a file you can already name is not a subagent job.

## Why this file exists

Without a standing instruction, the session default is to dispatch agents only when explicitly asked. That silently skips the review step `ce:writing-plans` treats as mandatory — the plan gets presented, nothing looks wrong, and nobody notices the pass did not happen.

Observed 2026-08-29 in `kirvin/self-hosted`: an eight-phase plan was presented without the `ce:devils-advocate` pass for exactly this reason. The inline review that replaced it still found four real problems — a set of test baselines that would have rotted on first use, a raw-store path that collided on same-day re-runs, unstated SQLite concurrency requirements, and an invariant whose enforcement had been overstated as a guarantee. The step earns its keep; it should not depend on someone remembering to ask for it.

Delete this file in a project to return to ask-first behaviour there.

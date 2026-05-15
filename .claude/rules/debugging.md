---
paths:
  - "**/*"
---

# Debugging

When investigating bugs or unexpected behavior, load `ce:systematic-debugging`.

## Local / dev issues

- **UI / browser** (blank screen, JS error, broken UX, CSP violation): run a
  headless Playwright capture against the broken URL and read the report's
  console errors *before* reading source — the cause is usually visible in
  the first console error. Wire a `make diagnose url=...` target if the
  project has a UI; otherwise use the Playwright CLI directly.
- **Service won't start**: read service logs first, not the source code.
- **Auth rejected**: verify credentials at the layer the request enters
  (header forwarded by gateway? token issuer matches verifier?).
- **DB-related**: check migrations are up to date before debugging behavior.

## Production issues — start with observability, not code

For any production latency or error report, **check the observability stack
before reading code**. Logs and traces tell you which layer is slow; reading
code first is guessing.

If the project has structured logs and tracing, the project's
`.claude/rules/observability.md` (project-specific) should have a triage
decision tree. If not, file an issue to add one — every production-bound
project benefits.

## Test failures

See `.claude/rules/test-failures.md`. No failure may be deferred regardless of
when it was introduced.

## HAR / network captures

If you have access to a browser HAR file (User → Network → Save All as HAR),
use the project's `make analyze-har FILE=...` target if it exists, or wire
one to `scripts/analyze-har.ts`. HAR analysis is the right tool for
client-side network issues; structured logs + traces are the right tool for
server-side latency.

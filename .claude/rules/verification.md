---
paths:
  - "**/*"
---

# Verification

Before claiming work is complete, load `ce:verification-before-completion`. Always verify:
- `npm run lint` passes
- `npm run build` succeeds
- Tests pass for modified service
- Feature works end-to-end (gateway → subgraph → DB)

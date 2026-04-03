---
paths:
  - "**/*"
---

# Debugging

When investigating bugs or unexpected behavior, load `ce:systematic-debugging`.

Service-specific tips:
- Gateway: check Apollo Federation composition errors in startup logs
- Auth: verify JWT in `Authorization` header is forwarded by gateway
- DB: check migrations are up (`npm run db:migrate:up`)

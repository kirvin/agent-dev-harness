# Implementation Patterns

Concrete patterns for building agent-optimized docs. Use these when creating or restructuring files.

---

## Pattern 1 — `reference.md` (the lookup doc)

**When to use:** Whenever agents would otherwise read infra files, source code, or multiple scattered docs to find a configuration value.

**Structure:**

```markdown
# [Project] — Quick Reference

> Lookup tables for [env vars / resource names / schema / logs].
> Agents: read this before grepping source files for configuration values.

---

## [Service/component name] — environment variables

| Variable | Value | Source |
|----------|-------|--------|
| `VAR_NAME` | actual-value-or-pattern | `infra/lambda.tf` line N |

---

## AWS resource names

| Resource | Name / ID |
|----------|-----------|
| S3 bucket | project-images-prod |
| DynamoDB table | project-records |

> **Live values:** run `tofu output` (or `terraform output`) to get ARNs and IDs.

---

## Database schema — `table-name`

**Table:** `table-name` · billing: PAY_PER_REQUEST

| Attribute | Type | Role |
|-----------|------|------|
| `id` | String (UUID) | Primary key |
| `tenant` | String | GSI partition key |

**GSI:** `by-tenant-index` — partition: `tenant`, sort: `created_at`

**Full item shape** (source: `src/models/record.ts`):
\`\`\`typescript
{ id: string; tenant: string; status: Status; ... }
\`\`\`

---

## Log locations

| Log group / file | Contents |
|-----------------|---------|
| `/aws/lambda/project-api` | API Lambda — requests, errors |

**Tail command:**
\`\`\`bash
aws logs tail /aws/lambda/project-api --follow --region us-east-1
\`\`\`
```

**Rules:**
- Group by component, not by type. All env vars + resource names for Lambda X together, not all env vars in one table and all names in another.
- Note the source file for every value so agents can verify currency.
- For secrets, document the env var name (e.g., `SECRET_ARN`) and where the secret lives (e.g., `aws secretsmanager get-secret-value --secret-id project/api-key`). Never put secret values in docs.
- Add a `> Live values: run X` note for anything that changes between environments.

---

## Pattern 2 — Summary table at top of EARS / policy docs

**When to use:** Any doc that is primarily written in SHALL/SHOULD/MUST legal language and is longer than ~80 lines.

**Structure:**

```markdown
# [Topic] Invariants

> Version: N.N · Last updated: YYYY-MM-DD

[one-line description of what this doc covers]

## Quick reference

| Topic | Rule | Section |
|-------|------|---------|
| Auth | WAF IP allowlist + JWT + MFA all required | §1 |
| Secrets | Secrets Manager only; never env vars | §3 |
| Critical gotcha | [one-sentence description of the non-obvious thing] | §7 |

---

## 1. [Section title]

[Full SHALL/SHALL NOT content...]
```

**Rules:**
- 7-10 rows maximum. If you have more, the doc needs splitting.
- One row per domain, not per invariant. "Auth" not "token expiry" and "MFA" and "PKCE" as separate rows.
- **Always include a row for the most dangerous gotcha** — the non-obvious constraint that, if missed, causes a hard-to-debug failure. In apollonius this was the Textract SNS publisher policy.
- Link to the section number, not to a heading anchor (section numbers are stable; heading text drifts).

---

## Pattern 3 — Entry-point pointer list (CLAUDE.md)

**When to use:** When adding a new doc that agents will regularly need.

**Structure:**

```markdown
## Project documentation

- `AGENTS.md` — Prerequisites, security rules, what never gets committed
- `docs/codebase-overview.md` — Repo layout, request flow, tech table (start here)
- `docs/reference.md` — Env vars, resource names, schema, log groups
- `docs/architecture.md` — Runtime topology, API contracts, data flows
- `docs/development.md` — Commands and local setup
- `docs/adr/README.md` — Architecture decision log
- `docs/features/` — Gherkin acceptance criteria; check before implementing
- `docs/ui/DESIGN.md` — Design system; read before touching UI code
```

**Rules:**
- One line per doc. Path + em dash + one-sentence description of when to read it.
- Order by frequency of use, not alphabetically. The most-read docs go first.
- Layer 5 specialist docs (EARS, individual ADRs) do not need individual entries — they're reachable via `docs/adr/README.md` and `docs/features/`.
- If a doc is gated by a rule (e.g., DESIGN.md only loads for UI tasks), note it: "read before touching UI code."

---

## Pattern 4 — Codebase overview navigation table

**When to use:** When creating or updating `docs/codebase-overview.md`.

**Structure:**

```markdown
## Where to go next

| I want to… | Go to |
|-----------|-------|
| Run the service locally | [`docs/development.md`](development.md) |
| Look up env vars, resource names, schema | [`docs/reference.md`](reference.md) |
| Understand the full data flow | [`docs/architecture.md`](architecture.md) |
| See why a technology was chosen | [`docs/adr/README.md`](adr/README.md) |
| Know what the system must do | [`docs/requirements.md`](requirements.md) |
| Find acceptance criteria for a feature | [`docs/features/`](features/) |
| Build or modify UI | [`docs/ui/DESIGN.md`](ui/DESIGN.md) — read first |
| Understand security constraints | [`docs/ears/security.md`](ears/security.md) |
```

**Rules:**
- Phrase rows as "I want to…" (task-oriented, not doc-oriented).
- Include `reference.md` second — it's the highest-frequency lookup that agents don't instinctively know to check.
- Every Layer 4 and Layer 5 doc with a dedicated entry point should have a row.
- Link using relative paths so the table works in any hosting environment.

---

## Pattern 5 — Env var mismatch detection

Before writing docs or code that references env var names, verify consistency:

```bash
# Find all env var reads in source
grep -rn "process\.env\." src/ lambdas/ --include="*.ts" | \
  sed 's/.*process\.env\.\([A-Z_]*\).*/\1/' | sort -u

# Find all env var sets in infra
grep -rn "^\s*[A-Z_]* \s*=" infra/*.tf | grep -v "#"
```

Any name in source that doesn't appear in infra (or vice versa) is a mismatch. Document the correct names (from source — source is the consumer) in `reference.md` and fix the infra to match.

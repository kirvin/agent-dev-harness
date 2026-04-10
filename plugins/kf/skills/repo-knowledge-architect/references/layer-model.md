# Layer Model — Detail

Full specification for each of the five knowledge layers. Use this when deciding what to create, what to restructure, and how layers should cross-reference each other.

---

## Layer 1 — Entry points (`CLAUDE.md`, `AGENTS.md`)

**Job:** First thing loaded in every session. Minimize token cost while ensuring agents know where to look.

**CLAUDE.md contains:**
- Doc pointers (one line each: path → one-sentence description)
- Issue tracking quick reference
- Session completion checklist

**AGENTS.md contains:**
- Prerequisites table (tools + verify commands)
- Security: what never gets committed (table with file pattern + why)
- Non-interactive shell command guidance (if relevant)

**Does NOT contain:**
- Architecture prose
- Command references (those go in `development.md`)
- Content that changes per feature (that drifts)

**Cross-referencing rule:** Every Layer 3-5 doc that agents regularly need should have a one-line pointer in CLAUDE.md. Do not point to every doc — only the ones an agent without context would fail to find.

**Size target:** CLAUDE.md under 60 lines of authored content (excluding the beads integration block). If it's growing, extract content to Layer 2 or 4.

---

## Layer 2 — Orientation (`docs/codebase-overview.md`)

**Job:** An agent new to the repo reads this once and knows where everything is.

**Contains:**
- Repo directory tree with one-line descriptions per directory and key file
- System request/data flow (prose or ASCII diagram — 10-20 lines)
- Key technologies table (layer → technology → why/ADR link)
- "Where to go next" navigation table (task → doc)

**Does NOT contain:**
- Full API contracts (those are Layer 4)
- Technology rationale (that's ADRs, Layer 5)
- Commands (those are `development.md`, Layer 4)

**Cross-referencing rule:** The navigation table is the primary index. Every significant doc in the repo should appear in it. The table should be the agent's default way of finding any Layer 4 or 5 doc.

**Size target:** ~100-150 lines. If it grows beyond this, something belongs in a deeper layer.

---

## Layer 3 — Lookup (`docs/reference.md`)

**Job:** Answer "what is the name/value/path of X?" without reading source code or infra files.

**Contains:**
- Environment variables (grouped by service/component — name, value/source, purpose)
- AWS or cloud resource names (service → resource name/ID)
- Database schema (table name, columns, indexes, types — enough to write a query)
- Log locations (log group/file path + how to tail them)
- Any other lookup-style content an agent would otherwise grep for

**Does NOT contain:**
- Why a resource exists (that's Layer 4 or 5)
- How to deploy or configure things (that's `development.md`)
- Architecture prose

**Cross-referencing rule:** `reference.md` should note where authoritative values come from (e.g., "run `tofu output` to get live ARNs"). It provides the current known values; the infra/source is the source of truth.

**Size target:** No limit — tables are scannable. Add sections as the system grows.

**When to create it:** As soon as an agent would need to read more than one source file to look up a configuration value. In practice: any project with infra-as-code, environment variables, or a database has enough lookup content to justify `reference.md`.

---

## Layer 4 — Depth (`docs/architecture.md`, `docs/development.md`, `docs/requirements.md`)

**Job:** Loaded when an agent is actively working on a specific area and needs full context.

**`architecture.md` contains:**
- System overview (service boundaries, deployment zones)
- Runtime topology diagram (Mermaid)
- Data flow / sequence diagram
- API contracts (request/response shapes, error codes)
- Storage topology (bucket layout, table structure)
- Failure modes

**`development.md` contains:**
- Local setup steps (copy config, install deps, run dev server)
- All `make` / `npm run` / CLI commands with descriptions
- One-time setup steps (documented for recovery)
- Infrastructure workflow (plan → apply sequence)

**`requirements.md` contains:**
- What the system does and for whom
- Functional requirements (MoSCoW)
- Out-of-scope boundaries
- Success criteria

**Cross-referencing rule:** Layer 4 docs should link to Layer 5 for rationale ("see ADR-006 for the event schema decision") and to Layer 3 for lookups ("see `reference.md` for resource names"). They should not duplicate that content.

---

## Layer 5 — Specialist (ADRs, EARS, Gherkin, design systems)

**Job:** Loaded for specific tasks. High information density; not needed on every session.

**ADRs (`docs/adr/`):**
- One file per significant technology decision
- Index at `docs/adr/README.md` — one row per ADR
- Contains: context, decision, alternatives, consequences
- Does NOT contain: requirements, invariants, acceptance criteria

**EARS (`docs/ears/`):**
- Non-negotiable system constraints (SHALL / SHALL NOT)
- One file per domain (privacy, security, data integrity)
- **Must have a summary table at the top** — 7-10 rows covering the most common questions. The body is for full legal-style prose; the table is for fast agent lookup.
- Does NOT contain: technology choices, user stories

**Gherkin features (`docs/features/`):**
- Given/When/Then acceptance criteria per user-facing behavior
- One `.feature` file per behavior
- Must be linked from CLAUDE.md and the codebase-overview navigation table
- Does NOT contain: implementation detail, architecture

**Design systems (`docs/ui/DESIGN.md` or similar):**
- Visual design tokens, component patterns, layout rules, motion specs
- Should be gated by a rule (e.g., `design-skills.md`) so it only loads for UI tasks
- Does NOT load unconditionally — it's large and only relevant for frontend work

---

## Cross-layer linking rules

| From | To | How |
|------|----|-----|
| CLAUDE.md | Any Layer 3-5 doc agent needs | One-line pointer with description |
| codebase-overview.md | All significant docs | Row in the "where to go next" table |
| reference.md | Infra/source (as authoritative source) | "Source: `infra/lambda.tf`" note per table |
| architecture.md | ADRs (for rationale) | "see ADR-006" inline link |
| architecture.md | reference.md (for resource names) | "see `docs/reference.md`" inline link |
| requirements.md §N | ADR (for schema definition) | "authoritative definition in ADR-006" |
| EARS files | Each other (privacy ↔ security) | "complements `docs/ears/privacy.md`" |

**Never cross-link downward to Layer 1 or 2 from Layer 5.** Deep docs should not reference CLAUDE.md.

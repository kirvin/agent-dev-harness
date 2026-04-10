---
name: repo-knowledge-audit
description: Audit a repository's documentation for agent efficiency — coverage gaps, stale references, token bloat, and missing quick-lookup content. Produces a prioritized findings report. No file writes. Use before kf:repo-knowledge-architect to design fixes.
---

# Repo Knowledge Audit

**Output only. No file writes during this skill.**

Produces a structured findings report. Run `kf:repo-knowledge-architect` to design and apply fixes.

---

## Reading order

Read in this sequence to minimize tokens. Stop reading a file once you have what you need.

```
1. CLAUDE.md / AGENTS.md      Entry points — what does the agent see first?
2. README.md                   Human-facing orientation
3. docs/codebase-overview.md   (if exists) — agent orientation layer
4. docs/development.md         Commands and setup
5. docs/ top-level *.md        Architecture, requirements, reference
6. docs/adr/README.md          Just the index table, not individual ADRs
7. docs/ears/*.md              Just headings — are summary tables present?
8. docs/features/              Just filenames — are they linked from entry points?
9. plans/                      Just README.md — is status current?
```

Only read individual ADR files, EARS bodies, or source code when a specific finding requires it.

---

## What to look for

### Category 1 — Bugs (wrong information, broken links)

- Cross-references pointing to files that don't exist
- ADR index entries with wrong titles (e.g., says "Vanilla JS" but ADR says "React")
- Wrong ADR number in a cross-reference (e.g., `ADR-002` where `ADR-006` was meant)
- Env var names that differ between infra config and source code
- IAM permission tables listing services the code doesn't actually use
- Status fields still showing DRAFT on completed work

**How to find env var mismatches:** grep source files for `process.env.VAR_NAME` patterns, then verify each name appears in the infra config with the same spelling.

### Category 2 — Missing content (forces extra tool reads)

Run these checks. Each item an agent can't answer from docs alone is a missing-content finding.

| Question | Where agent looks without docs | What to create |
|----------|-------------------------------|----------------|
| What env vars does Lambda X need? | Read `lambda.tf` + source | Env var table in `reference.md` |
| What are the actual AWS resource names? | Read `outputs.tf` or multiple `.tf` files | Resource name table in `reference.md` |
| What is the database schema? | Read migration files or ORM models | Schema section in `reference.md` |
| Where are the logs? | Read infra files | Log group table in `reference.md` |
| What does this endpoint return? | Read source or tests | API contract in `architecture.md` |
| What are the acceptance criteria for feature X? | No source of truth | Gherkin feature files + link from entry points |
| What CLI tools are required? | No source of truth | Prerequisites table in `AGENTS.md` |
| What must never be committed? | No source of truth | Security section in `AGENTS.md` |

### Category 3 — Token bloat (high cost vs. lookup frequency mismatch)

- Docs written entirely in SHALL/SHOULD legal language with no summary table at top
- Large docs loaded unconditionally for tasks that rarely need them
- The same data (event schema, document types, resource names) appearing in multiple docs with no "authoritative source" cross-reference
- Entry-point docs (CLAUDE.md, AGENTS.md) that contain prose instead of pointers

**Signal:** if a doc is >150 lines and contains mostly prose, check whether a 5-10 row summary table at the top would answer 80% of agent queries without reading the body.

### Category 4 — Discoverability gaps (content exists but agents won't find it)

- `docs/features/` or `plans/` not linked from CLAUDE.md or the codebase overview
- A well-written doc not referenced from the navigation table in the overview
- `AGENTS.md` exists but CLAUDE.md doesn't point to it
- Deep reference docs (ADRs, EARS) with no quick-scan entry point

---

## Output format

Report findings in three sections. Each finding gets: a one-sentence description, the file(s) involved, and the impact if not fixed.

```
## Bugs
- [file]: [what is wrong] → [consequence if unfixed]

## Missing content
- [what is missing] → [tool reads forced per agent session without it]

## Optimizations
- [file]: [what pattern would help] → [token savings / discoverability gain]
```

Order within each section by impact, highest first. Include a count at the top of each section.

---

## Anti-patterns that are NOT findings

Do not flag these — they are intentional:

- Large docs that are gated by a rule (e.g., DESIGN.md only loaded for UI tasks) — check the rules before flagging
- Duplicate summaries where one is explicitly marked "reference only; ADR is authoritative"
- EARS files written entirely in SHALL language — that is the correct format; flag only if there is no summary table
- Plans that are marked DRAFT but not yet started — flag only if the work is known to be complete

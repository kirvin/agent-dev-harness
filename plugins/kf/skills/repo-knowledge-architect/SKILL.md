---
name: repo-knowledge-architect
description: Design and implement agent-optimized knowledge structure for a code repository. Applies the five-layer progressive disclosure model, creates reference lookup docs, adds summary tables to long docs, and wires entry-point cross-links. Use after kf:repo-knowledge-audit to apply findings.
---

# Repo Knowledge Architect

**This skill writes files.** Run `kf:repo-knowledge-audit` first to identify what needs fixing.

---

## Topic selection

Load the reference that matches your current task:

| Task | Load |
|------|------|
| Deciding what docs to create, restructure, or merge | `references/layer-model.md` |
| Building a `reference.md` lookup doc or any fast-scan table | `references/patterns.md` |
| Both — full doc overhaul | load both |

---

## The five layers

Every agent-optimized repo has these five layers. Each has a single job. Missing layers force tool reads; duplicate layers cause drift.

| Layer | File(s) | Job | Max size |
|-------|---------|-----|----------|
| 1 — Entry points | `CLAUDE.md`, `AGENTS.md` | Pointers only — what to read, what never to commit, prerequisites | ~60 lines |
| 2 — Orientation | `docs/codebase-overview.md` | Repo tree, request/data flow, tech table, "where to go next" nav | ~120 lines |
| 3 — Lookup | `docs/reference.md` | Tables: env vars, resource names, schemas, log groups | any length |
| 4 — Depth | `docs/architecture.md`, `docs/development.md`, `docs/requirements.md` | Full data flows, API contracts, commands, product scope | any length |
| 5 — Specialist | ADRs, EARS, Gherkin features, design system | Loaded on demand for specific tasks | any length |

See `references/layer-model.md` for what each layer contains, what it must not contain, and how layers cross-reference each other.

---

## Decision rules

**Where does this content go?**

```
Is it a lookup value (name, ARN, env var, schema field, log path)?
  → reference.md (Layer 3)

Is it a pointer to where something lives?
  → CLAUDE.md or codebase-overview.md (Layer 1 or 2)

Is it a command or workflow a developer runs?
  → development.md (Layer 4)

Is it how the system is structured at runtime?
  → architecture.md (Layer 4)

Is it a non-negotiable constraint (security, privacy, data)?
  → docs/ears/*.md (Layer 5)

Is it a technology decision with rationale?
  → docs/adr/ADR-NNN.md (Layer 5)

Is it testable acceptance behavior?
  → docs/features/*.feature (Layer 5)
```

**Cross-reference, don't duplicate.** If content belongs in Layer 5, put a one-line pointer in Layer 2 and a row in Layer 3. Never copy the content up.

---

## Execution checklist

When applying audit findings to a repo, work in this order:

1. **Fix bugs first** — broken links, wrong env var names, stale ADR references. These take minutes and prevent agents from following bad paths.

2. **Create Layer 3 (reference.md) if missing** — highest token-reduction impact. Extract all lookup-style content from infra files, source code, and scattered docs into one file. See `references/patterns.md`.

3. **Add summary tables to long Layer 5 docs** — add a quick-reference table at the top of any EARS, security, or privacy doc. 7-10 rows covering the most common questions. See `references/patterns.md`.

4. **Wire entry points** — add missing pointers to CLAUDE.md and codebase-overview.md navigation table. Check: does every Layer 3-5 doc have a path from CLAUDE.md?

5. **Fix Layer 2 (orientation)** — if `docs/codebase-overview.md` doesn't exist, create it. If it exists, verify the repo tree, flow, and navigation table are current.

6. **Update stale status fields** — DRAFT plans that are complete, ADR index entries with wrong titles, requirements that don't reflect shipped features.

---

## Anti-patterns

| Pattern | Why it hurts agents |
|---------|-------------------|
| All guidance in CLAUDE.md | Loads on every session; token cost exceeds value for specialist content |
| No `reference.md` | Agents grep infra code to find env var names on every session |
| Summary tables omitted from EARS/security docs | Agents read 200 lines of SHALL language to answer a 3-word question |
| `docs/features/` not linked from entry points | Agents implement features without checking acceptance criteria |
| Duplicate content across layers with no authoritative pointer | Both copies drift; agents see conflicting information |
| Plans directory with no index or stale DRAFT status | Agents can't tell what's in progress vs. complete |
| Prerequisites only in README | README is for humans; agents start from CLAUDE.md |

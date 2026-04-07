---
name: spec-first
description: Spec-first development methodology for capturing requirements and architecture before writing code. Use when starting a new project, scoping a new feature, writing ADRs, documenting system invariants, or creating implementation plans. Covers the full sequence from product context through Gherkin acceptance criteria.
---

# Spec-First Development

**Core principle:** Write the spec before the code. Requirements, constraints, and architecture decisions are captured in version-controlled markdown before any implementation begins. Later steps depend on earlier ones — skipping forward creates rework.

## Topic Selection

Load the reference that matches your current step:

| Step | Working on... | Load | File |
|------|---------------|------|------|
| 1 | Classifying open questions, understanding the layer model | **Layers** | `references/layers.md` |
| 2 | Writing `docs/requirements.md` | (use `Skill(ce:planning-products)`) | — |
| 3 | Writing `docs/ears/*.md` system invariants | **EARS** | `references/ears-format.md` |
| 4 | Writing `docs/adr/ADR-NNN-*.md` | **ADR** | `references/adr-format.md` |
| 5 | Writing `docs/features/**/*.feature` | **Gherkin** | `references/gherkin-guide.md` |
| 6 | Writing `plans/` implementation phases | **Plans** | `references/plan-structure.md` |

Load the reference for your current step. Load multiple if the work spans steps.

---

## The Sequence

Follow this order. Each step depends on the one before it.

```
requirements.md        Product context, integration intent, MoSCoW scope
       ↓
docs/ears/privacy.md   Data classification, retention, security invariants
       ↓
ADRs                   One per significant technical decision
       ↓
docs/architecture.md   System design, Mermaid diagrams, API contracts
       ↓
Gherkin features       Acceptance criteria per user-facing behavior
       ↓
Implementation plans   Phased, one demoable deliverable per phase
```

Never write architecture before privacy constraints are known. Never write plans before ADRs are decided.

---

## Classifying Open Questions

Before answering any open question, assign it to a layer:

| Question type | Layer | Document |
|---------------|-------|----------|
| Product context, integration intent | Requirements | `docs/requirements.md` |
| Scope or priority | Requirements | `docs/requirements.md` MoSCoW |
| Data classification, privacy, retention | EARS | `docs/ears/privacy.md` |
| Technology choice with trade-offs | ADR | `docs/adr/ADR-NNN-*.md` |
| API contract between systems | ADR (after requirements context known) | `docs/adr/` |
| Behavior in a specific scenario | Gherkin | `docs/features/` |

A question that seems "architectural" may actually be a requirements question in disguise. Get the product context first — it often resolves the technical question or constrains the answer.

---

## Document Structure

Every project using this methodology creates:

```
docs/
  requirements.md         MoSCoW scope, integration context, type priorities
  architecture.md         System design, Mermaid diagrams, API contracts
  adr/
    README.md             Index of all ADRs (one line per ADR)
    ADR-001-*.md
    ADR-002-*.md
  ears/
    privacy.md            Data classification, retention, access invariants
    [domain].md           One file per system domain
  features/
    [domain]/
      index.md            Feature index for this domain
      [behavior].feature  One file per user-facing behavior

plans/
  YYYY-MM-DD-[feature]/
    README.md             Phase overview, tech stack, phase table, Beads IDs
    phase-1-[name].md
    phase-2-[name].md
```

---

## Anti-Patterns

| Pattern | Problem |
|---------|---------|
| Writing ADRs before requirements context | Answers the wrong question |
| Writing architecture before ADRs | Decisions aren't recorded; architecture becomes folk knowledge |
| Putting policy in ADRs | ADRs are for technology choices, not invariants — use EARS |
| Putting technology decisions in EARS | EARS is for constraints, not trade-off analysis — use ADRs |
| Writing plans before any specs | Plans have no foundation; they'll need rewriting after specs |
| Duplicating content across layers | Cross-reference instead; duplication drifts |
| One feature file covering multiple behaviors | Split by behavior; one `.feature` per user-facing capability |

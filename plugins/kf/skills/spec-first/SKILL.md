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

## Open Question Lifecycle

Writing an open question in a requirements doc is only useful if it gets answered. A question that stays in a table cell is invisible to `bd ready` — it will never surface again.

**Every open question must be assigned to one of three categories before the session ends:**

| Category | When to use | What to do |
|----------|-------------|------------|
| ✅ **Decided** | You can answer it now with available information | Answer inline, mark ✅, update the doc |
| ⏳ **Phase-deferred** | Not blocking current work; needs an answer before a specific future phase | Mark ⏳ with the gate phase and note "create issue at [Phase X] kickoff" |
| **Decision-blocking** | Left unanswered, this blocks implementation or causes rework | `bd create` immediately — before the session ends |

**This rule applies when writing a new requirements doc AND when updating an existing one.** Any open question you encounter in a doc you're touching — even if you didn't write it — must be categorized before the session closes.

### How to tell which category

Ask: "If we start Phase A tomorrow, does this question need an answer first?"
- Yes → decision-blocking. Create an issue now.
- No, but it blocks a later phase → phase-deferred. Note the gate.
- You already know the answer → decide it inline.

### Questions that seem urgent but usually aren't blocking

- Performance targets for a future-phase feature (Phase A doesn't need them)
- Mobile/responsive support (desktop-first is the safe default; defer)
- Exact error message copy (implement the path, polish copy later)
- Internal naming conventions (answer inline or defer; rarely blocks anything)

### Questions that look like details but are actually blocking

- Auth model for a new app → blocks the skeleton (can't build an auth gate without it)
- App naming → blocks monorepo structure and all existing file references
- Shared component strategy → blocks whether a shared package gets built at all

### Session-close checklist for spec work

Before marking any requirements or planning work complete:

```
[ ] Every open question in docs you touched is categorized (✅ / ⏳ / blocking issue)
[ ] Decision-blocking questions have a bd create issue filed
[ ] Any spec with a phased delivery plan has a Phase A planning issue in beads
```

The third item is the most commonly missed: requirements docs that define Phase A/B/C but have no engineering issues are also dead ends. The planning issues bridge the spec to buildable work.

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

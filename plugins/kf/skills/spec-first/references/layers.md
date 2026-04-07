# Layer Map

The spec-first methodology uses six distinct layers. Each has a single job. Content that belongs in one layer should not appear in another — cross-reference instead.

## The Six Layers

### 1. Requirements (`docs/requirements.md`)

**Job:** What the system does and for whom. Scope decisions. Integration context.

**Contains:**
- MoSCoW feature list (Must / Should / Could / Won't)
- User stories and jobs to be done
- Integration boundaries (what other systems does this connect to, and why)
- Document type priorities or domain-specific scope decisions

**Does NOT contain:** Technology choices, implementation constraints, invariants

**Written as:** Plain English with MoSCoW markers. Use the `ce:planning-products` skill.

---

### 2. EARS Invariants (`docs/ears/*.md`)

**Job:** System-level constraints that are non-negotiable regardless of feature scope.

**Contains:**
- Data handling, privacy, and retention policies
- Security constraints (what the system SHALL NOT do)
- Integrity rules (what must always be true)
- One file per domain: `privacy.md`, `storage.md`, `[pipeline-name].md`

**Does NOT contain:** Trade-off analysis, technology choices, user stories

**Written as:** EARS sentences (SHALL, SHALL NOT, WHEN/WHILE/IF patterns)

**Relationship to ADRs:** EARS constraints often force ADR decisions. "Images SHALL NOT leave the local network" is an EARS invariant that rules out cloud OCR — the OCR choice then becomes an ADR.

---

### 3. ADRs (`docs/adr/ADR-NNN-*.md`)

**Job:** Record technology decisions, the alternatives considered, and the consequences accepted.

**Contains:**
- The decision (one clear statement)
- Context that forced the decision
- Alternatives with pros/cons
- Positive and negative consequences

**Does NOT contain:** Functional requirements, invariants, acceptance criteria

**Written as:** ADR format with Status, Context, Decision, Alternatives, Consequences

**Relationship to EARS:** ADRs implement the constraints that EARS defines. Never write an ADR before reading the relevant EARS file.

---

### 4. Architecture (`docs/architecture.md`)

**Job:** Show how the system is built. Service topology, data flow, API contracts.

**Contains:**
- Mermaid diagrams (container map, data flow, sequence diagrams)
- Service boundaries and responsibilities
- API contracts between services
- Storage topology

**Does NOT contain:** Why a technology was chosen (that's ADRs), functional requirements, acceptance criteria

**Relationship to ADRs:** Architecture is the result of ADR decisions. Every significant architectural choice should trace back to an ADR.

---

### 5. Gherkin Features (`docs/features/**/*.feature`)

**Job:** Executable acceptance criteria for every user-facing behavior.

**Contains:**
- Given/When/Then scenarios
- Happy paths and error states
- Concrete values (exact status codes, field names, error codes)

**Does NOT contain:** Implementation detail, technology choices, system invariants (those are EARS)

**Relationship to requirements:** One `.feature` file per behavior listed in `requirements.md`. If a behavior has no feature file, it has no acceptance criteria and cannot be verified.

---

### 6. Plans (`plans/YYYY-MM-DD-[feature]/`)

**Job:** Break the spec into executable, phased implementation work.

**Contains:**
- Phase breakdown (one demoable deliverable per phase)
- Task steps with explicit file paths
- Verify commands per task
- References to spec documents (not duplicates of them)

**Does NOT contain:** Requirements, design decisions, invariants — those are the spec; the plan references them

**Relationship to all other layers:** Plans are written last. They assume all other layers are complete and stable.

---

## Decision Tree: Where Does This Go?

```
Is this a constraint that applies regardless of features?
  YES → EARS

Is this a technology choice with trade-offs?
  YES → ADR

Is this what the system does (not how)?
  YES → requirements.md

Is this how the system is structured?
  YES → architecture.md

Is this a testable behavior in a specific scenario?
  YES → Gherkin feature file

Is this how to build it, step by step?
  YES → Plan
```

If it fits multiple: the more foundational layer wins. Requirements before ADRs. EARS before architecture. Architecture before plans.

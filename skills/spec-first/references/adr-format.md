# ADR Format

## When to Write an ADR

Write an ADR for every decision that:
- Chooses between two or more real technology options
- Has consequences that are hard to reverse
- Will be questioned later ("why did we pick X?")

Do NOT write an ADR for: obvious choices with no real alternative, implementation details within a decided technology, or decisions that don't survive past a single sprint.

## File Naming

```
docs/adr/ADR-NNN-short-description.md
```

Pad with leading zeros: `ADR-001`, `ADR-002`. Keep the description short and lowercase-kebab-case.

Always update `docs/adr/README.md` with a one-line entry when adding a new ADR.

## Template

```markdown
# ADR-NNN: [Decision Title]

**Status:** Draft | Accepted | Superseded by ADR-NNN
**Date:** YYYY-MM-DD

## Context

[What situation forced this decision? What constraints exist? What would happen
if we made no decision? 2-4 sentences — enough context that someone unfamiliar
with the project understands why this decision matters.]

## Decision

[The choice made. One clear statement. Not a list of options — that goes in
Alternatives. State the decision directly: "We will use X" not "We considered
using X."]

## Alternatives Considered

| Option | Pros | Cons | Why rejected |
|--------|------|------|--------------|
| [Option A] | | | |
| [Option B] | | | |
| [Chosen option] | | | N/A — selected |

## Consequences

**Positive:**
- [Specific benefit]
- [Specific benefit]

**Negative:**
- [Specific cost or constraint accepted]
- [What this decision rules out]
```

## Writing Style

State the decision before the context. Readers scan for the outcome — put it near the top.

Name tradeoffs explicitly. "This approach requires X" is better than omitting the cost. Honest ADRs get trusted; sanitized ADRs get ignored.

Avoid: "We decided to leverage the synergies of..." Just say what you picked and why.

## Example

```markdown
# ADR-003: Local Tesseract for OCR

**Status:** Accepted
**Date:** 2026-04-06

## Context

The pipeline needs to extract text from photos of physical documents taken on a
laptop camera. Two paths exist: run OCR locally (Tesseract) or call a cloud
vision API. The system is self-hosted on a home network and processes sensitive
household documents (bills, medical EOBs, tax notices).

## Decision

We will use Tesseract 5 running inside the back-end container for OCR. No image
content will be sent to cloud OCR services.

## Alternatives Considered

| Option | Pros | Cons | Why rejected |
|--------|------|------|--------------|
| Google Cloud Vision | Higher accuracy, handles poor lighting | Images leave the machine; cost per call; requires internet | Privacy constraint from docs/ears/privacy.md §2 |
| AWS Textract | Strong on structured documents (forms, tables) | Same privacy issue; more complex auth | Same as above |
| Tesseract 5 (local) | Free, fully private, no network dependency | Lower accuracy on low-res photos | Selected |

## Consequences

**Positive:**
- Document images never leave the local network
- No per-call cost; no API key to manage
- Works offline

**Negative:**
- Accuracy lower than cloud alternatives, especially in poor lighting
- Requires image pre-processing (contrast, deskew) to reach acceptable confidence
- Container image is larger (~200MB for Tesseract + language packs)
```

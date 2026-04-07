# EARS Format (Easy Approach to Requirements Syntax)

EARS files capture system invariants — the things the system SHALL or SHALL NOT do regardless of feature scope. These are non-negotiable constraints, not user preferences.

## When to Use EARS vs Other Layers

| Write in EARS when... | Write elsewhere when... |
|-----------------------|------------------------|
| The constraint applies to the whole system, not one feature | The behavior is feature-specific → Gherkin |
| It's a policy (privacy, retention, security) | It's a trade-off between options → ADR |
| Violating it would be a bug, not a gap | It's a priority or scope choice → requirements.md |

## File Organization

One file per system domain. Common files:

```
docs/ears/
  privacy.md          # Data handling, retention, access constraints
  storage.md          # Persistence, integrity, backup constraints
  [pipeline].md       # Per-pipeline invariants (ingest, processing, etc.)
  [domain].md         # One per major system domain
```

## EARS Sentence Patterns

EARS uses structured natural language to make requirements unambiguous and testable.

| Pattern | Syntax | Use when |
|---------|--------|----------|
| Ubiquitous | The system SHALL [action] | Always true, no trigger |
| Event-driven | WHEN [event], the system SHALL [action] | Triggered by something that happens |
| State-driven | WHILE [state], the system SHALL [action] | True as long as a condition holds |
| Conditional | IF [condition], the system SHALL [action] | True when a precondition is met |
| Negative | The system SHALL NOT [action] | Hard prohibition |

## Template

```markdown
# [Domain] Invariants

> Version: 0.1
> Last updated: YYYY-MM-DD

## [Section Title]

The system SHALL [invariant].

WHEN [triggering event], the system SHALL [required behavior].

The system SHALL NOT [prohibited behavior].

IF [condition], the system SHALL [conditional requirement].

## [Next Section]

...
```

## Writing Style

- One requirement per sentence. Never combine two SHALLs with "and."
- Be specific enough that you could write a failing test for it.
- Use SHALL for mandatory. Use SHOULD for recommended but not absolute.
- Avoid "appropriate," "reasonable," "adequate" — if you can't define it, it's not testable.

## Example

```markdown
# Privacy Invariants

> Version: 0.1
> Last updated: 2026-04-06

## Image Storage

The system SHALL store captured document images only on the local filesystem
volume configured at startup. Images SHALL NOT be written to cloud storage,
third-party services, or any location outside the configured volume.

WHEN an image is captured, the system SHALL assign it a UUID-based filename
with no metadata encoded in the filename itself (no date, document type,
or user-identifiable strings in the path).

The system SHALL NOT transmit raw image data to any external service. Only
extracted text (post-OCR) may be sent to external AI APIs for classification
and summarization.

## Retention

WHEN an image has been successfully processed and an action item has been
enqueued, the system SHALL retain the image for a minimum of 30 days.

IF the operator has configured a retention period, the system SHALL purge
images older than that period during the nightly maintenance window.

The system SHALL NOT purge any image that has not been successfully processed
and had its action item enqueued.

## Access

The system SHALL require a valid API token on all endpoints that return,
display, or reference captured images.

WHILE an image is being processed, the system SHALL NOT expose it via any
public or unauthenticated endpoint.
```

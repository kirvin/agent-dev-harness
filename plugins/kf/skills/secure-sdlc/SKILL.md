---
name: secure-sdlc
description: Security reference library for this stack. Covers threat modeling (STRIDE), security requirements (EARS), pre-merge security review checklist, and incident response playbooks. Load when designing integrations, reviewing security-sensitive PRs, or responding to incidents.
---

# Secure SDLC

A reference library for security work in this stack. Load the relevant reference for
the current task rather than reading everything upfront.

## When to load each reference

| Task | Reference |
|------|-----------|
| Threat modeling a new feature or integration | `references/threat-model.md` |
| Writing EARS security invariants | `references/security-requirements.md` |
| Pre-merge security review of a PR | `references/pre-merge-checklist.md` |
| Responding to a credential leak or incident | `references/incident-response.md` |

## Quick orientation

**Threat model** → identify what could go wrong (STRIDE) → feeds into EARS + ADR layers

**Security requirements** → EARS invariants that encode non-negotiable security constraints;
one file per domain (`auth.md`, `data.md`, `pipeline.md`)

**Pre-merge checklist** → runnable commands + human-review items; must pass before merging
security-sensitive changes

**Incident response** → step-by-step playbooks for AWS credential compromise, Figma token
leak, git history exposure; each playbook is self-contained

## Stack context

This skill is calibrated for the agent-dev-harness stack:
- AWS Bedrock as the Claude Code provider (SSO-based auth via AWS profiles)
- GitHub Actions CI with SHA-pinned actions
- Figma API integration (personal access tokens)
- Beads issue tracker for finding remediation
- Node.js / TypeScript projects

## Relationship to other security skills

- `kf:security-sweep` — retrospective analysis *after* code is written; this skill is for *during* design and review
- `ce:managing-pipelines` — CI/CD hardening; complements this skill for pipeline-specific changes

---

Load the reference that matches your current task. Do not load all four unless the situation requires it.

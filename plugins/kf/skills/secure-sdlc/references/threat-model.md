# STRIDE Threat Model Template

Pre-adapted for the ki-dev-toolkit stack. Fill in the blank rows for the feature under analysis.
Delete rows that don't apply. Add rows for additional components.

## Feature / Component Being Modeled

**Feature:** _________________
**Date:** _________________
**Components in scope:** _________________

---

## Component Map

Before running STRIDE, enumerate the components and trust boundaries:

```
[Browser / Claude Code CLI]
        ↓ HTTPS
[GitHub API / gh CLI]
        ↓
[AWS Bedrock API]          ← trust boundary: AWS account
        ↓
[Claude Model]
```

Adapt this for the feature being modeled. Mark trust boundaries with `←`.

---

## STRIDE Analysis

### S — Spoofing (Identity)

*Can an attacker impersonate a user, service, or component?*

| Attack vector | Likelihood | Mitigation |
|---------------|-----------|------------|
| GitHub token stolen from .env | MEDIUM | Use gh auth (keychain); never commit tokens |
| AWS SSO session hijacked | LOW | Short-lived SSO tokens; MFA on AWS account |
| _(feature-specific)_ | | |

**EARS invariant from HIGH-likelihood threats:**
`The system SHALL NOT accept requests from unauthenticated callers on any endpoint that reads or writes user data.`

---

### T — Tampering (Integrity)

*Can an attacker modify data in transit or at rest?*

| Attack vector | Likelihood | Mitigation |
|---------------|-----------|------------|
| GitHub Actions workflow modified via mutable tag | HIGH | SHA-pin all action refs |
| .env file modified on compromised machine | MEDIUM | Treat .env as credentials; rotate on compromise |
| _(feature-specific)_ | | |

**EARS invariant:**
`The system SHALL verify the integrity of all external dependencies before execution (SHA pinning for Actions, lockfiles for npm).`

---

### R — Repudiation (Audit Trails)

*Can a user deny an action with no audit trail to refute it?*

| Attack vector | Likelihood | Mitigation |
|---------------|-----------|------------|
| No record of who ran a deployment | MEDIUM | Git commits + beads issues trace all changes |
| _(feature-specific)_ | | |

---

### I — Information Disclosure

*Can an attacker access data they shouldn't?*

| Attack vector | Likelihood | Mitigation |
|---------------|-----------|------------|
| Credential leaked in log output | MEDIUM | Never log credential values; log presence only |
| Token in error message returned to caller | MEDIUM | Sanitize error messages at API boundary |
| Secret in git history | HIGH | .gitignore enforced; rotate on exposure |
| _(feature-specific)_ | | |

**EARS invariant:**
`The system SHALL NOT include credential values in log output, error messages, or API responses.`

---

### D — Denial of Service

*Can an attacker make the system unavailable?*

| Attack vector | Likelihood | Mitigation |
|---------------|-----------|------------|
| AWS Bedrock API rate limit exhausted | LOW | Retry with backoff; monitor usage |
| _(feature-specific)_ | | |

---

### E — Elevation of Privilege

*Can a low-privilege user gain higher access?*

| Attack vector | Likelihood | Mitigation |
|---------------|-----------|------------|
| CI job gains write access via GITHUB_TOKEN | MEDIUM | Set `permissions: contents: read` on all workflows |
| IAM role too broad | MEDIUM | Least-privilege IAM; scope to specific actions and resources |
| _(feature-specific)_ | | |

**EARS invariant:**
`GitHub Actions workflows SHALL declare the minimum permissions required and SHALL NOT use default (write-all) token permissions.`

---

## Output

From this analysis, file:
1. EARS invariants in `docs/ears/<feature>-threats.md` for each HIGH-likelihood threat
2. ADRs in `docs/adr/` for each mitigation that involves a technology choice
3. Beads tasks for any unmitigated HIGH threats

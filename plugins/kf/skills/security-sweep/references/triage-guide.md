# Security Finding Triage Guide

Assign P0, P1, or P2 to each finding from a security sweep. The severity determines
whether the finding blocks merge and what the remediation timeline is.

---

## Severity Definitions

### P0 — Critical: Block merge, fix immediately

The vulnerability is exploitable now and could result in:
- Credential or token theft
- Unauthorized access to production systems or data
- Data exfiltration
- Account takeover

**Criteria — any one is sufficient:**
- [ ] A real credential value is present in source, logs, or history
- [ ] An auth check is completely absent on a route that reads or writes data
- [ ] SQL or command injection is directly reachable from an external input
- [ ] A secret is printed in CI output where it could be read from run logs
- [ ] An unpinned `pull_request_target` workflow can execute untrusted code with secrets

**Action:** Stop the PR. Fix before any merge. If the credential is already in a pushed
commit, rotate it immediately (don't wait for the fix).

```bash
bd create \
  --title="[Security][P0] <category>: <brief description>" \
  --description="File: <path>:<line>
Finding: <description>
Risk: <impact if exploited>
Fix: <specific remediation>" \
  --type=bug \
  --priority=0
```

---

### P1 — High: Fix before merge

The vulnerability is exploitable under realistic conditions but requires more than
trivially discovering the repo or making a basic request:
- Information disclosure in error messages or logs (not immediately actionable but enables further attacks)
- Missing auth check on a low-sensitivity route
- Overly broad IAM scope that isn't actively being abused but creates blast radius
- Unpinned GitHub Actions (supply chain risk, not actively exploited)

**Criteria — any one is sufficient:**
- [ ] Sensitive data (non-credential) in log output or error responses
- [ ] Auth present but insufficient (e.g., checks authentication but not authorization)
- [ ] IAM role or token scope clearly broader than needed
- [ ] GitHub Actions steps use mutable version tags
- [ ] npm package with no repository URL or known low-quality signals added

**Action:** Fix before merge. If blocking deployment, file the task and fix in the same
PR. If the fix is non-trivial, it can be a follow-on PR if merge is urgent — but the
issue must be filed before merging.

```bash
bd create \
  --title="[Security][P1] <category>: <brief description>" \
  --description="File: <path>:<line>
Finding: <description>
Risk: <impact>
Fix: <remediation>" \
  --type=bug \
  --priority=1
```

---

### P2 — Low: File a task, safe to merge

Defense-in-depth gap with low exploitation likelihood. The system is not immediately
at risk, but the finding represents a gap in security posture:
- Missing `permissions:` key on a workflow that doesn't handle secrets
- Informational log line that includes non-sensitive user data
- Dependency without lockfile update (but the package itself is trusted)
- EARS invariant exists but is not enforced by a test

**Criteria:**
- [ ] Finding requires multiple other failures to be exploitable
- [ ] The attack surface is internal-only or requires prior access
- [ ] The gap is in defense-in-depth, not a primary control

**Action:** File a beads task. Can merge. Note the task in the PR description.

```bash
bd create \
  --title="[Security][P2] <category>: <brief description>" \
  --description="File: <path>:<line>
Finding: <description>
Risk: <low-risk explanation>
Fix: <remediation>" \
  --type=task \
  --priority=2
```

---

## Triage decision tree

```
Is a real credential value exposed (in source, logs, or git history)?
  YES → P0

Is the finding directly exploitable from an external request with no auth?
  YES → P0 (injection, auth bypass) or P1 (info disclosure)

Does the finding require attacker access to something they already shouldn't have?
  YES → P2

Is the finding about missing defense-in-depth (SHA pinning, permissions keys, log hygiene)?
  Usually P1 for active risk (missing auth), P2 for hardening gaps (missing permissions key)

Is the finding a false positive (placeholder value, example file, allowlisted pattern)?
  → Not a finding; add to .gitleaks.toml allowlist if scanner flagged it
```

---

## Escalation

If a finding is P0 and the credential may already be in a pushed commit:
1. Rotate the credential **now** — before fixing the code
2. Notify any collaborators who may have pulled the affected branch
3. Check git remote for any forks or CI caches that may have the value

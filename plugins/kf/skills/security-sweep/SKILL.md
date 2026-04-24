---
name: security-sweep
description: Retrospective security analysis of a PR or branch. Scans changed files for findings across seven categories, triages by severity, and creates beads tasks for remediation. Use after code is written to catch what proactive review missed.
---

# Security Sweep

Retrospective security analysis of a PR or branch. Run after code is written — this
complements the proactive design-time review in `kf:secure-sdlc`.

## Step 1 — Establish scope

Identify what to scan:

```bash
# Changed files in a PR branch vs main
git diff --name-only main...HEAD

# Changed files in a specific commit range
git diff --name-only <base>..<head>
```

If the user names a PR number: `gh pr diff <n> --name-only`

## Step 2 — Scan by category

Load `references/finding-categories.md` for the full category definitions, bad/good
examples, and detection patterns. Scan each changed file for:

| Category | What to look for |
|----------|-----------------|
| **CRED** | Hardcoded credentials, tokens, or keys |
| **AUTH** | Missing/bypassable auth checks, insecure session handling |
| **INJECT** | SQL/command/template injection, unsanitized user input |
| **EXPOSE** | Sensitive data in logs, error messages, or API responses |
| **SUPPLY** | Unpinned dependencies, untrusted packages, mutable action tags |
| **SCOPE** | Over-privileged IAM roles, excessive API scopes |
| **CI** | Unsafe workflow triggers, missing permissions, secret exposure in logs |

For each finding, note:
- File and line number
- Category
- Brief description of the risk
- Suggested remediation

## Step 3 — Triage findings

Load `references/triage-guide.md` for full P0/P1/P2 criteria.

Quick reference:
- **P0** — Exploitable now, data loss or account takeover possible → block merge, fix immediately
- **P1** — Significant risk, exploitable under realistic conditions → fix before merge
- **P2** — Defense-in-depth gap, low likelihood → file a task, can merge

## Step 4 — Create beads tasks

For P0 and P1 findings, create a task before reporting:

```bash
bd create \
  --title="[Security][<CATEGORY>] <brief description>" \
  --description="File: <path>:<line>
Finding: <description>
Risk: <what an attacker could do>
Fix: <remediation steps>" \
  --type=bug \
  --priority=<0 for P0, 1 for P1, 2 for P2>
```

## Step 5 — Output sweep report

```markdown
## Security Sweep — <branch or PR> — <date>

**Scope:** <files scanned count> files changed

### Findings

#### [P0] CRED — <file>:<line>
<description and remediation>
Beads: <id>

#### [P1] AUTH — <file>:<line>
...

### Summary
<N> findings: <P0 count> critical, <P1 count> high, <P2 count> low
<Merge recommendation: block / fix before merge / safe to merge with tasks filed>
```

## No findings

If no findings are identified, output:

```
Security sweep complete — no findings in <N> changed files.
Safe to merge from a security standpoint.
```

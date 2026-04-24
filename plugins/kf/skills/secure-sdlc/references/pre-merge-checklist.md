# Pre-Merge Security Checklist

Run this before merging any PR that touches security-sensitive code (auth, credentials,
external integrations, CI/CD, user input handling).

---

## Runnable checks

Run these commands against the PR branch:

```bash
# 1. Scan for potential credential patterns in changed files
git diff main...HEAD | grep -iE '(api_key|secret|token|password|private_key)\s*=\s*["\x27][^"\x27<>]{10,}'

# 2. Verify no .env files are staged
git diff --name-only main...HEAD | grep -E '\.env($|\.)'

# 3. Check for unpinned GitHub Actions (tags instead of SHAs)
grep -rE 'uses:\s+\S+@v[0-9]' .github/workflows/ 2>/dev/null && echo "UNPINNED ACTIONS FOUND"

# 4. Check npm audit if package.json changed
git diff --name-only main...HEAD | grep -q 'package' && npm audit --audit-level=high

# 5. Gitleaks scan (if installed)
command -v gitleaks &>/dev/null && gitleaks detect --source . --no-git
```

All five should produce no output / no findings before proceeding.

---

## Human review items

Check each item that applies to this PR:

**Credentials and secrets**
- [ ] No credential values hardcoded in changed files
- [ ] `.env.example` updated if new env vars were added
- [ ] New credentials are sourced from `.env.local` (not `.env` if `.env` is committed)

**Authentication and authorization**
- [ ] New endpoints/routes have auth checks (not just happy-path)
- [ ] Permission checks can't be bypassed by manipulating request parameters
- [ ] Error responses don't leak internal state or stack traces

**Input handling**
- [ ] User-supplied input is validated before use in queries, commands, or API calls
- [ ] File paths derived from user input are validated (no path traversal)
- [ ] No `eval`, `exec`, or dynamic command construction with user input

**External integrations**
- [ ] New external service: threat model completed (see `threat-model.md`)
- [ ] API tokens stored in `.env.local`, not hardcoded
- [ ] External API errors handled without leaking response bodies to end users

**CI/CD**
- [ ] New workflow steps use SHA-pinned actions
- [ ] Workflow `permissions:` key is present and scoped to minimum needed
- [ ] No secrets printed in `run:` steps (including via `--verbose` or `--debug` flags)
- [ ] No `pull_request_target` with untrusted code checkout

**Dependencies**
- [ ] New packages verified for provenance (see `dependency-audit.md` rule)
- [ ] No known CVEs in newly added packages (`npm audit`)
- [ ] Lockfile updated and committed

---

## Merge decision

| Result | Action |
|--------|--------|
| All runnable checks clean + all applicable human items checked | Safe to merge |
| Any runnable check has findings | Fix before merge |
| Human item is unclear | Ask for clarification; do not assume it's fine |
| Finding is low risk but can't fix now | File a P2 beads task, note in PR description, then merge |
| Finding is HIGH risk | Block merge; fix first |

# CI Security

## SHA-pinned actions

All GitHub Actions in this repo are pinned to full commit SHAs, not mutable version tags.
This prevents supply-chain attacks where a tag like `v4` is moved to point at malicious code.

### How to resolve a SHA from a tag

```bash
# Get the commit SHA for a specific release tag
gh api /repos/<owner>/<action>/git/refs/tags/<tag> --jq '.object.sha'

# If the result is an annotated tag object (not a commit), dereference it:
gh api /repos/<owner>/<action>/git/tags/<tag-sha> --jq '.object.sha'
```

Example — resolving `actions/checkout@v4`:
```bash
gh api /repos/actions/checkout/git/refs/tags/v4 --jq '.object.sha'
# → 34e114876b0b11c390a56381ad16ebd13914f8d5
```

Then use the SHA in the workflow:
```yaml
- uses: actions/checkout@34e114876b0b11c390a56381ad16ebd13914f8d5  # v4
```

Always leave the human-readable tag in a comment so future maintainers know which version this SHA corresponds to.

### Keeping SHAs up to date

Enable Dependabot for GitHub Actions to get automated SHA bump PRs:

```yaml
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: github-actions
    directory: /
    schedule:
      interval: weekly
```

Dependabot will open PRs that update both the SHA and the comment tag when a new release is available.

---

## Gitleaks secret scanning

Secret scanning runs via `gitleaks/gitleaks-action` in `.github/workflows/secret-scanning.yml`.

### Current status

The workflow is set to `workflow_dispatch` (manual trigger only) until a `GITLEAKS_LICENSE` secret is configured. Running without a license produces warnings but still scans; the license enables additional features and removes the rate limit for large repos.

### Setting up GITLEAKS_LICENSE

1. Obtain a license from [gitleaks.io](https://gitleaks.io) (free for open source)
2. Add it as a repository secret: **Settings → Secrets → Actions → New repository secret**
   - Name: `GITLEAKS_LICENSE`
   - Value: your license key
3. Update `secret-scanning.yml` to add push/PR triggers alongside `workflow_dispatch`:
   ```yaml
   on:
     push:
       branches: [main]
     pull_request:
       branches: [main]
     workflow_dispatch:
   ```

### False positive handling

Known false positives are allowlisted in `.gitleaks.toml`. To add a new allowlist entry:

1. Identify whether it's a path-based or pattern-based false positive
2. Add to `.gitleaks.toml` under `paths` (glob) or `regexes` (regex)
3. Add a comment explaining why it's a false positive
4. Commit with a message like `chore: allowlist <description> in gitleaks`

Never disable a rule entirely — use targeted allowlist entries instead.

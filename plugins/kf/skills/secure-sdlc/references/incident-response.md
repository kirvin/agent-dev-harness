# Incident Response Playbooks

Self-contained playbooks for the most likely security incidents in this stack.
Each playbook is independent — jump directly to the relevant one.

---

## Playbook 1: AWS Credential Compromise

**Symptoms:** Unexpected AWS API calls, unknown IAM activity, billing spike, alert from AWS GuardDuty.

### Immediate (within 15 minutes)

```bash
# 1. Identify the compromised credential
# Check which profile / key is involved from the alert or log

# 2. Revoke the compromised access key (if long-lived key)
aws iam delete-access-key --access-key-id <KEY_ID> --profile <admin-profile>

# 3. For SSO-based compromise: revoke active sessions
# Go to: AWS Console → IAM Identity Center → Users → <user> → Active sessions → Revoke all
```

### Short-term (within 1 hour)

```bash
# 4. Review CloudTrail for actions taken with the compromised credential
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=Username,AttributeValue=<username> \
  --start-time <incident-start> \
  --profile <admin-profile>

# 5. Check for any new IAM users, roles, or policies created
aws iam list-users --profile <admin-profile>
aws iam list-roles --profile <admin-profile> | grep -v 'AWS::'
```

### Recovery

1. Rotate the credential — issue a new key or re-provision SSO
2. Update `.env` / `.env.local` in all projects using the old credential
3. Audit what data or services the compromised credential had access to
4. File a beads issue for any data that may have been exfiltrated
5. Review and tighten IAM permissions if the incident revealed over-privileging

---

## Playbook 2: Figma API Token Leak

**Symptoms:** Token found in git history, logs, or public-facing output; unexpected Figma API activity.

### Immediate

1. **Revoke the token in Figma:**
   Figma → Settings → Account → Personal access tokens → Delete the token

2. **Verify revocation:**
   ```bash
   curl -H "X-Figma-Token: <OLD_TOKEN>" https://api.figma.com/v1/me
   # Should return 403 after revocation
   ```

### Clean up

```bash
# If found in git history — remove from all commits
# WARNING: this rewrites history; coordinate with any collaborators first
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch .env' \
  --prune-empty --tag-name-filter cat -- --all

# OR use git-filter-repo (preferred over filter-branch):
pip install git-filter-repo
git filter-repo --path .env --invert-paths
```

After rewriting: force-push all branches, rotate the GitHub token used for the push if it was also exposed.

### Recovery

1. Generate a new Figma personal access token
2. Update `.env.local` in all affected projects
3. Re-run `./scripts/setup.sh` or manually update `.claude/settings.local.json`

---

## Playbook 3: Secret Exposed in Git History

**Symptoms:** CI scanner (gitleaks) flags a commit; manual discovery of a secret in history.

### Assessment

```bash
# Find commits containing the secret pattern
git log --all --oneline -S '<partial-secret-or-pattern>'

# Identify which files in history contain it
git log --all --full-history -- '*.env'
git log --all --full-history -- '**/*.json'
```

### If the secret is still in HEAD

```bash
# Remove the file from HEAD and .gitignore it
echo "<file>" >> .gitignore
git rm --cached <file>
git commit -m "chore: remove accidentally committed secret"
```

Then rotate the credential immediately — treat it as compromised regardless of whether the commit was pushed.

### If the secret is only in history (not HEAD)

Use `git-filter-repo` to remove it from all history:

```bash
# Remove a specific file from all history
git filter-repo --path <file> --invert-paths

# Remove by regex pattern (e.g., a specific token value)
git filter-repo --replace-text <(echo 'LITERAL:<token>==>' )
```

After rewriting:
1. Force-push all branches: `git push --force-with-lease`
2. Notify any collaborators to re-clone
3. Rotate the exposed credential

### Allowlisting a false positive

If the scanner flagged a non-secret (placeholder, example value):

```bash
# Add to .gitleaks.toml
[allowlist]
regexes = ["<pattern-that-matched>"]
```

Commit the allowlist update with a comment explaining why it's a false positive.

---

## Post-Incident

For any incident:

1. **Create a beads issue** documenting what happened, impact, and steps taken
2. **Update rules / EARS invariants** if the incident revealed a gap
3. **Add a gitleaks allowlist entry** if a false positive triggered the response
4. **Review `.gitignore`** — if a secret escaped via a missing pattern, add it now

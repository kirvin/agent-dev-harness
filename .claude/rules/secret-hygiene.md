# Secret Hygiene

Never hardcode credentials, tokens, or secrets in source files, commit messages, or log output.

## Where secrets live

| Credential type | Variable name | File |
|----------------|---------------|------|
| AWS profile/keys (deploy-to-AWS projects only) | `AWS_PROFILE` / `AWS_ACCESS_KEY_ID` etc. | `~/.aws/config` (SSO) or `~/.aws/credentials` — never `.env` |
| Figma API token | `FIGMA_API_TOKEN` | `.env.local` (gitignored) |
| GitHub token | managed by `gh auth` | system keychain |
| Beads credentials | auto-managed | `.beads/.beads-credential-key` (gitignored) |
| External API keys | `<SERVICE>_API_KEY` | `.env.local` |

## Rules

- Use `.env.local` (gitignored) for sensitive values; use `.env` only for non-sensitive config that is safe to commit
- Provide `.env.example` with placeholder values for every entry a developer needs to set
- Never log credential values — log only that a credential is present or absent
- Never pass secrets as CLI arguments — they appear in process lists and shell history
- Rotate immediately if a secret is accidentally committed; treat it as compromised even if the commit is removed from history

## .gitignore requirements

`install-to-project.sh` enforces these patterns in every provisioned project:

```
.env
.env.*
!.env.example
.claude/settings.local.json
.beads/.beads-credential-key
```

When adding a new secret type, add its `.gitignore` pattern and a placeholder to `.env.example` in the same commit as the feature that introduces it.

## Pre-commit check

Before every commit, scan staged files for patterns that look like credentials:

```bash
git diff --cached | grep -iE '(api_key|secret|token|password|private_key)\s*=\s*["\x27][^"\x27<>]{8,}'
```

If anything matches, remove the value before committing.

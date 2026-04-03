# Beads ↔ GitHub Issue Linking

When closing a beads issue that was synced from a GitHub issue, use
`./scripts/bd-close.sh` (or `make bd-close`) instead of `bd close`.
This automatically closes the linked GitHub issue with a comment.

## Usage

```bash
# Direct script
./scripts/bd-close.sh the-nerdery-xxxx
./scripts/bd-close.sh the-nerdery-xxxx --reason="Fixed by ..."

# Multiple issues at once
./scripts/bd-close.sh the-nerdery-xxxx the-nerdery-yyyy --reason="..."

# Via make
make bd-close id=the-nerdery-xxxx
make bd-close id=the-nerdery-xxxx reason="Fixed by ..."
```

## When it applies

The script checks whether the beads issue description contains a GitHub
issue URL (`https://github.com/.../issues/<n>`). If it does, it closes
that GitHub issue after closing the beads task. If there is no linked
issue the script behaves exactly like `bd close`.

## When to use plain `bd close` instead

- Closing infrastructure/CI/test issues with no GitHub counterpart
- Closing beads issues that were not synced from GitHub

---
paths:
  - "**/*"
---

# Git Commits

## Branch before committing

When `main` is branch-protected (direct pushes blocked), switch to a feature branch before any code or config commit:

```bash
git checkout -b <beads-id>-<short-slug>   # e.g. proj-abc1-add-foo
```

Use the active beads issue ID as the prefix when one exists. Commit on the branch, push the branch, and open a PR when the work is ready to merge. PR timing is decoupled from session end — push WIP branches at session close even if no PR is opened yet.

Exceptions (no branch needed):
- Beads-only changes (auto-export to Dolt, not git)
- No file modifications at all (read-only sessions)

If your project's `main` is *not* branch-protected, this section can be ignored — but enabling branch protection is recommended once the project has more than one contributor (human or AI).

## Always include the active beads task ID

Before writing a commit message, run `bd list --status=in_progress` to find the
active task ID. Include it in the commit message footer:

```
feat: add encrypted backup infrastructure

Adds Ansible role with systemd timers and age-encrypted backup scripts.

Beads: <project>-<id>
Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
```

If no task is in progress, omit the `Beads:` line.

**This is mandatory.** The `Beads:` footer is the only link between git history
and the issue tracker. Do not omit it when a task is active.

## CI fixes

After committing a fix for a failing GitHub Actions run, push to the branch
that the failing run was triggered from — not necessarily the current local
branch. Check `gh run view <id>` to confirm the target branch name, then:

```bash
git push origin HEAD:<failing-branch-name>
```

No need to ask for confirmation — pushing to fix a broken CI run is
pre-authorized.

# GitHub Pull Requests

Create pull requests from the branch that contains your commits.  PRs should be created against the `main` branch, unless the PR is intended to merge into a different branch (e.g. a release branch or a feature branch that is still in development).

When creating a PR, include a clear description of the changes being made and any relevant context for reviewers. If the PR addresses a specific issue, reference it in the description (e.g. "Fixes #123").
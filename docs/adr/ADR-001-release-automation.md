# ADR-001: Release kf with intuit/auto and Conventional Commits

**Status:** Accepted
**Date:** 2026-09-24
**Supersedes:** none (replaces the release-please setup, which had no ADR)

## Context

Consuming projects only receive kf changes after `plugins/kf/.claude-plugin/plugin.json`
gets a new version. release-please was configured to bump it, but it never produced
a release. Every run since at least 2026-04-28 failed with "GitHub Actions is not
permitted to create or approve pull requests". Every version up to 1.4.5 was bumped by
hand. In September 2026 a privacy fix for a consuming project sat merged but
unreleased because nobody bumped the version (claude-config-wte).

Alternatives considered:

| Option | Why not |
|--------|---------|
| Keep release-please and allow Actions to open PRs | Adds a second PR per release to merge by hand, which is the step that kept being skipped. It also needs a repo-wide permission change. |
| semantic-release | Similar model. The maintainer chose intuit/auto. |
| auto's `version-file` plugin | It writes the whole file as the version string, and can't update one field in `plugin.json`. |
| auto's `git-tag` plugin (tags only) | Claude Code compares the `plugin.json` version, so a tag alone never reaches consumers. |
| Manual bumps | This is the process that failed. |

## Decision

On every push to `main`, `.github/workflows/release.yml` runs `auto shipit --no-changelog`
with the `conventional-commits` plugin and a local plugin, `scripts/auto-plugin-json.js`.
The commit types merged since the latest GitHub release choose the bump. For a release,
the local plugin writes `plugin.json`, commits `chore(release): kf vX.Y.Z` to `main`,
and pushes an annotated tag with `git push --atomic`. auto then publishes GitHub release
notes. CI fails PRs whose title or commit subjects are not Conventional Commits.

## Consequences

**Positive**
- Merging a `fix` or `feat` PR is the whole release. Consumers see a new version immediately.
- Release notes are generated and grouped by change type.
- The version file has a single writer.

**Negative**
- **Commit subjects now matter.** An untyped commit contributes no bump, and the CI check exists to catch that.
- **The workflow token can write to `main`.** It has `contents: write` and pushes directly to `main`. That works only because `main` has no branch protection or ruleset, even though `CLAUDE.md` describes it as write-protected. If protection is turned on, the release push fails, and the fix is one of:
  - a ruleset bypass for GitHub Actions
  - a GitHub App token with bypass
  - a PR-based release flow

  Revisit this ADR then.
- **The octokit overrides are unsupported.** auto 11.3.6, the latest, pins old `@octokit/*` packages with 14 moderate ReDoS advisories (GHSA-h5c3-5r3r-rr8q, GHSA-rmvr-2pp2-xj38, GHSA-xx4v-prfh-6cgc). `package.json` overrides them to patched releases, several majors newer than auto declares. `@octokit/plugin-throttling` is left at auto's version because v8 renamed a required option.
  - What was verified: auto's GitHub reads against this repo, and a full `auto latest --dry-run`.
  - What wasn't verified until the first real release: the write calls, which are creating a release and pushing.
  - Re-check `npm audit` and drop the overrides when auto updates octokit.
- **A skip-type merge holds the release.** If the newest merge is `docs`, `chore` and so on, auto waits, and earlier `fix`/`feat` changes ship with the next releasable merge.

## Threat notes (STRIDE, pipeline scope)

| Threat | Mitigation |
|--------|------------|
| Tampering: a malicious dependency's install script uses the persisted checkout token to push to `main` | `npm ci --ignore-scripts`; exact pins plus a lockfile generated on linux/amd64; `npm audit` clean |
| Tampering or elevation: PR title injection into a workflow script | The title reaches the check only through an env var. The check job has read-only permissions and `persist-credentials: false`. |
| Elevation: token scope | Workflow default `contents: read`. The release job adds `contents: write` and read-only `pull-requests` and `issues`. The job runs only on `push` to `main`, never on `pull_request` or `pull_request_target`. |
| Denial of service: two merges race | `concurrency: release` serialises runs. Each run fast-forwards to the current `main` before releasing. If `main` moves mid-run anyway, `--atomic` means the rejected push leaves neither commit nor tag, and the next merge releases those changes. |
| Repudiation | Release commits are authored by `github-actions[bot]`, and each run is logged in Actions. |

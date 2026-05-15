---
paths:
  - "**/*"
---

# Verification

Before claiming work is complete, load `ce:verification-before-completion`.

## Canonical commands per workspace

Use the Makefile target — it is the single source of truth and prevents
re-discovering script names every session.

| Workspace | Verify gate | Equivalent |
|-----------|-------------|------------|
| `<workspace-1>` | `make verify-<name>` | `make typecheck && make test` |
| `<workspace-2>` | `make verify-<name>` | ... |

Each consuming project should fill in this table with its own workspaces
and the canonical commands per workspace. `make help` lists every target
with descriptions.

## What each gate checks

- **typecheck**: per-workspace `tsc --noEmit` against the workspace's own
  `tsconfig.json`. Catches type errors that ts-jest / Vitest miss (those run
  transpile-only).
- **test**: Jest, Vitest, pytest — whatever the workspace uses.
- **build**: only required before deploy, not as a per-PR gate. CI runs it.
- **e2e**: only when the change touches a cross-service path.

## TypeScript compilation — never at monorepo root

**Never run `npx tsc --noEmit` at the monorepo root** — it OOMs (the union of
all workspace types is far larger than any single workspace and tsc has no
incremental cache at the root). Always use the per-workspace `make typecheck-*`
target.

For quick syntax/import checks on individual TS files, esbuild is faster:
```bash
npx esbuild <file.ts> --bundle=false --platform=node
```

## Closing major beads issues

When closing a beads issue that involved non-trivial code changes, debugging,
architecture decisions, or new patterns — load the `task-completion` project
skill instead of calling `ce:verification-before-completion` directly. It wraps
the verification gate and adds a mini lessons-learned retro before `bd close`.

Skip the extended protocol for: dep bumps, one-line fixes, doc-only changes,
orphan closes.

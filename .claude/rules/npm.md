# npm Package Management

## Always install packages using a Linux Docker container in CI-targeted projects

Never run bare `npm install` on macOS to generate a lockfile that will be used in Linux CI/CD. npm on macOS only writes the current platform's optional native binaries into the lockfile — transitive optional packages (like `@rollup/rollup-linux-x64-gnu`) never appear as entries, which causes CI failures.

The fix: run `npm install` inside a `linux/amd64` Docker container so the lockfile includes all platform variants.

## Cross-platform optional dependencies

When adding a package that ships platform-specific native binaries (esbuild, lightningcss, rollup, sharp, @swc/*, canvas, etc.), explicitly list all needed platform variants in `optionalDependencies`:

```json
"optionalDependencies": {
  "@esbuild/linux-x64": "^0.27.3",
  "@esbuild/linux-arm64": "^0.27.3",
  "@esbuild/darwin-x64": "^0.27.3",
  "@esbuild/darwin-arm64": "^0.27.3",
  "@rollup/rollup-linux-x64-gnu": "^4.0.0",
  "@rollup/rollup-linux-arm64-gnu": "^4.0.0",
  "@rollup/rollup-darwin-arm64": "^4.0.0",
  "@rollup/rollup-darwin-x64": "^4.0.0"
}
```

This ensures the lockfile always includes the entries needed for CI, even if someone runs plain `npm install` locally.

Packages to watch for: `esbuild`, `lightningcss`, `rollup`, `sharp`, `@swc/*`, `@rollup/*`, `canvas`.

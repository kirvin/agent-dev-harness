// Tests for scripts/auto-plugin-json.js against real git in throwaway repos.
// Run: node --test tests/*.test.js
const { test } = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { execFileSync } = require("node:child_process");

const { readVersion, nextVersion, release } = require("../scripts/auto-plugin-json.js");

const PLUGIN_JSON = `{
  "name": "kf",
  "description": "Example plugin",
  "version": "1.4.5",
  "author": {
    "name": "Someone"
  }
}
`;

function repoWithPluginJson(contents = PLUGIN_JSON) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "auto-plugin-json-"));
  const git = (...args) => execFileSync("git", args, { cwd: dir, encoding: "utf8" }).trim();
  git("init", "-q");
  git("config", "user.name", "Test");
  git("config", "user.email", "test@example.invalid");
  const file = path.join(dir, "plugin.json");
  fs.writeFileSync(file, contents);
  git("add", ".");
  git("commit", "-q", "-m", "chore: initial");
  return { dir, file, git };
}

test("readVersion returns the version field", () => {
  const { file } = repoWithPluginJson();
  assert.equal(readVersion(file), "1.4.5");
});

test("readVersion rejects a version that is not x.y.z", () => {
  const { file } = repoWithPluginJson(PLUGIN_JSON.replace("1.4.5", "1.4"));
  assert.throws(() => readVersion(file), /not x\.y\.z/);
});

test("nextVersion applies semver bumps", () => {
  assert.equal(nextVersion("1.4.5", "patch"), "1.4.6");
  assert.equal(nextVersion("1.4.5", "minor"), "1.5.0");
  assert.equal(nextVersion("1.4.5", "major"), "2.0.0");
});

test("nextVersion refuses bumps it does not support", () => {
  assert.throws(() => nextVersion("1.4.5", "prerelease"), /unsupported bump/);
  assert.throws(() => nextVersion("1.4.5", ""), /unsupported bump/);
});

test("release writes the version, commits it, and tags the commit", () => {
  const { file, git } = repoWithPluginJson();
  const tag = release({ file, bump: "minor", prefix: (v) => `v${v}`, cwd: path.dirname(file) });

  assert.equal(tag, "v1.5.0");
  assert.equal(fs.readFileSync(file, "utf8"), PLUGIN_JSON.replace("1.4.5", "1.5.0"), "only the version changes");
  assert.equal(git("log", "-1", "--format=%s"), "chore(release): kf v1.5.0");
  assert.equal(git("rev-parse", "v1.5.0^{commit}"), git("rev-parse", "HEAD"));
  assert.equal(git("cat-file", "-t", "v1.5.0"), "tag", "annotated, so git push --follow-tags sends it");
  assert.equal(git("status", "--porcelain"), "");
});

test("release honours an explicit version", () => {
  const { file } = repoWithPluginJson();
  const tag = release({ file, bump: "patch", useVersion: "2.0.0", prefix: (v) => `v${v}`, cwd: path.dirname(file) });
  assert.equal(tag, "v2.0.0");
  assert.equal(readVersion(file), "2.0.0");
});

test("release in dry-run mode changes nothing", () => {
  const { file, git } = repoWithPluginJson();
  const head = git("rev-parse", "HEAD");
  const tag = release({ file, bump: "patch", dryRun: true, prefix: (v) => `v${v}`, cwd: path.dirname(file) });

  assert.equal(tag, "v1.4.6");
  assert.equal(fs.readFileSync(file, "utf8"), PLUGIN_JSON);
  assert.equal(git("rev-parse", "HEAD"), head);
  assert.equal(git("tag", "--list"), "");
});

test("release leaves other uncommitted changes out of the release commit", () => {
  const { dir, file, git } = repoWithPluginJson();
  fs.writeFileSync(path.join(dir, "stray.txt"), "not part of the release\n");
  git("add", "stray.txt");
  release({ file, bump: "patch", prefix: (v) => `v${v}`, cwd: dir });
  assert.deepEqual(git("show", "--name-only", "--format=", "HEAD").split("\n"), ["plugin.json"]);
});

// Tests for scripts/auto-plugin-json.js against real git in throwaway repos.
// Run: node --test tests/*.test.js
const { test, after } = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { execFileSync } = require("node:child_process");

const KfPluginJsonPlugin = require("../scripts/auto-plugin-json.js");
const { readVersion, nextVersion, maxVersion, release } = KfPluginJsonPlugin;

const TMP = fs.mkdtempSync(path.join(os.tmpdir(), "auto-plugin-json-"));
after(() => fs.rmSync(TMP, { recursive: true, force: true }));

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
  const dir = fs.mkdtempSync(path.join(TMP, "repo-"));
  const git = (...args) => execFileSync("git", args, { cwd: dir, encoding: "utf8", stdio: "pipe" }).trim();
  git("init", "-q", "-b", "main");
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

test("maxVersion picks the highest x.y.z and ignores anything else", () => {
  assert.equal(maxVersion("1.4.4", "v1.4.5"), "1.4.5");
  assert.equal(maxVersion("1.10.0", "v1.9.9"), "1.10.0");
  assert.equal(maxVersion("1.4.4", "3f2c9ab"), "1.4.4");
});

test("release rejects an explicit version that is not x.y.z, and accepts a v prefix", () => {
  const { file } = repoWithPluginJson();
  const cwd = path.dirname(file);
  assert.throws(() => release({ file, bump: "patch", useVersion: "banana", prefix: (v) => `v${v}`, cwd }), /not x\.y\.z/);
  assert.equal(fs.readFileSync(file, "utf8"), PLUGIN_JSON, "a rejected version leaves the file untouched");
  assert.equal(release({ file, bump: "patch", useVersion: "v2.1.0", prefix: (v) => `v${v}`, cwd }), "v2.1.0");
  assert.equal(readVersion(file), "2.1.0");
});

// --- the plugin as auto drives it ---------------------------------------------

// A stand-in for auto exposing only what the plugin touches; the hooks run for real.
function fakeAuto({ latestRelease = "v1.4.5" } = {}) {
  const taps = {};
  const hook = (name) => ({ tapPromise: (_, fn) => { taps[name] = fn; } });
  const logs = [];
  return {
    taps,
    logs,
    hooks: { getPreviousVersion: hook("getPreviousVersion"), version: hook("version"), publish: hook("publish") },
    prefixRelease: (v) => `v${v}`,
    baseBranch: "main",
    git: { getLatestRelease: async () => latestRelease },
    logger: { log: { info: (m) => logs.push(m) } },
  };
}

// repo + a bare "origin" that already has main
function repoWithRemote() {
  const repo = repoWithPluginJson();
  const bare = fs.mkdtempSync(path.join(TMP, "remote-"));
  execFileSync("git", ["init", "-q", "--bare", "-b", "main", bare]);
  repo.git("remote", "add", "origin", bare);
  repo.git("push", "-q", "origin", "HEAD:main");
  repo.remote = (...args) => execFileSync("git", ["--git-dir", bare, ...args], { encoding: "utf8", stdio: "pipe" }).trim();
  repo.bare = bare;
  return repo;
}

function applyPlugin(repo, auto) {
  new KfPluginJsonPlugin({ file: repo.file, cwd: repo.dir }).apply(auto);
  return auto;
}

test("getPreviousVersion reports plugin.json's version as a tag", async () => {
  const repo = repoWithPluginJson();
  const auto = applyPlugin(repo, fakeAuto());
  assert.equal(await auto.taps.getPreviousVersion(), "v1.4.5");
});

test("version hook bumps from the latest GitHub release when plugin.json lags behind", async () => {
  const repo = repoWithPluginJson(PLUGIN_JSON.replace("1.4.5", "1.4.4"));
  const auto = applyPlugin(repo, fakeAuto({ latestRelease: "v1.4.5" }));
  await auto.taps.version({ bump: "patch" });
  assert.equal(readVersion(repo.file), "1.4.6", "not 1.4.5, which is already released");
  assert.equal(repo.git("describe", "--exact-match", "HEAD"), "v1.4.6");
});

test("version hook in quiet dry-run prints the tag and changes nothing", async (t) => {
  const repo = repoWithPluginJson();
  const auto = applyPlugin(repo, fakeAuto());
  const printed = [];
  t.mock.method(console, "log", (m) => printed.push(m));
  await auto.taps.version({ bump: "minor", dryRun: true, quiet: true });
  assert.deepEqual(printed, ["v1.5.0"]);
  assert.equal(readVersion(repo.file), "1.4.5");
  assert.equal(repo.git("tag", "--list"), "");
});

test("publish pushes the release commit and its annotated tag to origin", async () => {
  const repo = repoWithRemote();
  const auto = applyPlugin(repo, fakeAuto());
  await auto.taps.version({ bump: "patch" });
  await auto.taps.publish({});
  assert.equal(repo.remote("rev-parse", "main"), repo.git("rev-parse", "HEAD"));
  assert.equal(repo.remote("cat-file", "-t", "v1.4.6"), "tag");
});

test("publish is atomic: if main moved, neither the commit nor the tag lands", async () => {
  const repo = repoWithRemote();
  const other = fs.mkdtempSync(path.join(TMP, "other-"));
  execFileSync("git", ["clone", "-q", repo.bare, other]);
  const otherGit = (...args) => execFileSync("git", args, { cwd: other, stdio: "pipe" });
  otherGit("-c", "user.name=Other", "-c", "user.email=o@example.invalid", "commit", "-q", "--allow-empty", "-m", "fix: meanwhile");
  otherGit("push", "-q", "origin", "HEAD:main");
  const movedMain = repo.remote("rev-parse", "main");

  const auto = applyPlugin(repo, fakeAuto());
  await auto.taps.version({ bump: "patch" });
  await assert.rejects(auto.taps.publish({}));
  assert.equal(repo.remote("rev-parse", "main"), movedMain);
  assert.equal(repo.remote("tag", "--list"), "", "no orphan tag on the remote");
});

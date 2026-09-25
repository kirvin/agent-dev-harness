// auto-plugin-json.js — intuit/auto plugin that keeps the kf version in
// plugins/kf/.claude-plugin/plugin.json.
//
// auto's version-file plugin writes the whole file as the version, and the npm
// plugin wants a package.json, so neither fits. This follows version-file's
// shape: read the previous version, then on release write the file, commit it,
// tag it (annotated, so --follow-tags sends it), and push atomically.
//
// Dependency-free on purpose: tests require it without installing auto.

const fs = require("node:fs");
const { execFileSync } = require("node:child_process");

const DEFAULT_FILE = "plugins/kf/.claude-plugin/plugin.json";
const BUMPS = ["major", "minor", "patch"];
const SEMVER = /^\d+\.\d+\.\d+$/;

function readVersion(file) {
  const version = JSON.parse(fs.readFileSync(file, "utf8")).version;
  if (!SEMVER.test(version || "")) {
    throw new Error(`${file}: version "${version}" is not x.y.z`);
  }
  return version;
}

// "v1.4.5" or "1.4.5" -> "1.4.5"; anything else (e.g. a commit SHA) -> null.
function parseVersion(value) {
  const version = String(value || "").replace(/^v/, "");
  return SEMVER.test(version) ? version : null;
}

function compareVersions(a, b) {
  const pa = a.split(".").map(Number);
  const pb = b.split(".").map(Number);
  for (let i = 0; i < 3; i++) if (pa[i] !== pb[i]) return pa[i] - pb[i];
  return 0;
}

// The higher of the given versions, ignoring any that are not x.y.z.
function maxVersion(...values) {
  return values
    .map(parseVersion)
    .filter(Boolean)
    .reduce((max, v) => (max === null || compareVersions(v, max) > 0 ? v : max), null);
}

function nextVersion(current, bump) {
  if (!BUMPS.includes(bump)) {
    throw new Error(`unsupported bump "${bump}"; expected one of ${BUMPS.join(", ")}`);
  }
  const [major, minor, patch] = current.split(".").map(Number);
  if (bump === "major") return `${major + 1}.0.0`;
  if (bump === "minor") return `${major}.${minor + 1}.0`;
  return `${major}.${minor}.${patch + 1}`;
}

// Replace only the version value, so the rest of the file keeps its formatting.
function writeVersion(file, version) {
  const text = fs.readFileSync(file, "utf8");
  const updated = text.replace(/("version"\s*:\s*")[^"]*(")/, `$1${version}$2`);
  fs.writeFileSync(file, updated);
  let written;
  try {
    written = readVersion(file);
  } finally {
    if (written !== version) fs.writeFileSync(file, text);
  }
  if (written !== version) {
    throw new Error(`${file}: the top-level "version" field was not updated to ${version}`);
  }
}

// Returns the release tag. With dryRun, computes it and changes nothing.
// `previous` is the version to bump from; it defaults to the file's version.
function release({ file, bump, useVersion, previous, dryRun = false, prefix, cwd = process.cwd() }) {
  let version;
  if (useVersion) {
    version = parseVersion(useVersion);
    if (!version) throw new Error(`--use-version "${useVersion}" is not x.y.z`);
  } else {
    version = nextVersion(previous || readVersion(file), bump);
  }
  const tag = prefix(version);
  if (dryRun) return tag;

  const git = (...args) => execFileSync("git", args, { cwd, stdio: "pipe" });
  writeVersion(file, version);
  git("commit", "-m", `chore(release): kf ${tag}`, "--", file);
  git("tag", "-a", tag, "-m", `kf ${tag}`);
  return tag;
}

class KfPluginJsonPlugin {
  constructor(options = {}) {
    this.name = "kf-plugin-json";
    this.file = options.file || DEFAULT_FILE;
    this.cwd = options.cwd || process.cwd();
    // Push to the named remote, whose credentials actions/checkout persisted,
    // rather than auto.remote, which embeds the token in the URL (and argv).
    this.remote = options.remote || "origin";
  }

  apply(auto) {
    auto.hooks.getPreviousVersion.tapPromise(this.name, async () =>
      auto.prefixRelease(readVersion(this.file))
    );

    auto.hooks.version.tapPromise(this.name, async ({ bump, useVersion, dryRun, quiet }) => {
      // Bump from the higher of plugin.json and the latest GitHub release, so a
      // stale file can never propose a tag that already exists.
      const previous = maxVersion(readVersion(this.file), await auto.git.getLatestRelease());
      const tag = release({
        file: this.file,
        bump,
        useVersion,
        previous,
        dryRun,
        prefix: (v) => auto.prefixRelease(v),
        cwd: this.cwd,
      });
      if (dryRun && quiet) console.log(tag);
      else auto.logger.log.info(dryRun ? `Would release ${tag}` : `Committed and tagged ${tag}`);
    });

    // --atomic: the branch and the tag land together or not at all, so a push
    // rejected because main moved cannot leave an orphan tag behind.
    auto.hooks.publish.tapPromise(this.name, async () => {
      execFileSync(
        "git",
        ["push", "--atomic", "--follow-tags", this.remote, `HEAD:${auto.baseBranch}`],
        { cwd: this.cwd, stdio: "pipe" }
      );
      auto.logger.log.info(`Pushed ${auto.baseBranch} and tags to ${this.remote}`);
    });
  }
}

module.exports = KfPluginJsonPlugin;
module.exports.default = KfPluginJsonPlugin;
module.exports.readVersion = readVersion;
module.exports.nextVersion = nextVersion;
module.exports.maxVersion = maxVersion;
module.exports.release = release;

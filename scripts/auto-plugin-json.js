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

function readVersion(file) {
  const version = JSON.parse(fs.readFileSync(file, "utf8")).version;
  if (!/^\d+\.\d+\.\d+$/.test(version || "")) {
    throw new Error(`${file}: version "${version}" is not x.y.z`);
  }
  return version;
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
  if (updated === text && readVersion(file) !== version) {
    throw new Error(`${file}: could not find a "version" field to update`);
  }
  fs.writeFileSync(file, updated);
}

// Returns the release tag. With dryRun, computes it and changes nothing.
function release({ file, bump, useVersion, dryRun = false, prefix, cwd = process.cwd() }) {
  const version = useVersion || nextVersion(readVersion(file), bump);
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
  }

  apply(auto) {
    auto.hooks.getPreviousVersion.tapPromise(this.name, async () =>
      auto.prefixRelease(readVersion(this.file))
    );

    auto.hooks.version.tapPromise(this.name, async ({ bump, useVersion, dryRun, quiet }) => {
      const tag = release({
        file: this.file,
        bump,
        useVersion,
        dryRun,
        prefix: (v) => auto.prefixRelease(v),
      });
      if (dryRun && quiet) console.log(tag);
      else auto.logger.log.info(dryRun ? `Would release ${tag}` : `Committed and tagged ${tag}`);
    });

    // --atomic: the branch and the tag land together or not at all, so a push
    // rejected because main moved cannot leave an orphan tag behind.
    auto.hooks.publish.tapPromise(this.name, async () => {
      execFileSync(
        "git",
        ["push", "--atomic", "--follow-tags", auto.remote, `HEAD:${auto.baseBranch}`],
        { stdio: "inherit" }
      );
    });
  }
}

module.exports = KfPluginJsonPlugin;
module.exports.default = KfPluginJsonPlugin;
module.exports.readVersion = readVersion;
module.exports.nextVersion = nextVersion;
module.exports.release = release;

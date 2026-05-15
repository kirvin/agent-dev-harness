/**
 * HAR file analyzer for diagnosing network performance issues.
 *
 * Parses a browser HAR capture and prints:
 *  - Full request timeline with wait (TTFB) vs receive breakdown
 *  - Slow requests flagged (>2s wait)
 *  - Failed / aborted requests
 *  - Connection saturation detection (6-per-host limit pattern)
 *  - P50 / P95 / max summary
 *
 * Usage:
 *   make analyze-har FILE=path/to/capture.har
 *   npx tsx scripts/analyze-har.ts path/to/capture.har
 */

import * as fs from 'fs';
import * as path from 'path';

// ---- HAR types (subset we use) -----------------------------------------

interface HarTimings {
  blocked?: number;
  dns?: number;
  connect?: number;
  ssl?: number;
  send?: number;
  wait?: number;
  receive?: number;
}

interface HarEntry {
  startedDateTime: string;
  time: number;
  request: { method: string; url: string };
  response: { status: number; statusText?: string; _error?: string };
  timings: HarTimings;
}

interface HarLog {
  log: { version: string; entries: HarEntry[] };
}

// ---- Formatting helpers -------------------------------------------------

const RESET = '\x1b[0m';
const RED = '\x1b[31m';
const YELLOW = '\x1b[33m';
const GREEN = '\x1b[32m';
const BOLD = '\x1b[1m';
const DIM = '\x1b[2m';
const CYAN = '\x1b[36m';

function color(c: string, s: string) { return `${c}${s}${RESET}`; }
function bold(s: string)  { return color(BOLD, s); }
function dim(s: string)   { return color(DIM, s); }
function red(s: string)   { return color(RED, s); }
function yellow(s: string){ return color(YELLOW, s); }
function green(s: string) { return color(GREEN, s); }
function cyan(s: string)  { return color(CYAN, s); }

function fmtMs(ms: number | undefined | null): string {
  if (ms == null || ms < 0) return dim('  —  ');
  if (ms >= 60_000) return yellow(`${(ms / 60_000).toFixed(1)}m`);
  if (ms >= 1_000)  return yellow(`${(ms / 1_000).toFixed(1)}s`);
  return `${ms.toFixed(0)}ms`;
}

function fmtUrl(url: string, maxLen = 80): string {
  try {
    const u = new URL(url);
    const short = u.hostname + u.pathname + (u.search ? '?' + u.search.slice(1, 20) + (u.search.length > 21 ? '…' : '') : '');
    return short.length > maxLen ? '…' + short.slice(-(maxLen - 1)) : short;
  } catch {
    return url.slice(-maxLen);
  }
}

function fmtStatus(status: number): string {
  if (status === 0)  return red(' 0  ');
  if (status === -1) return yellow(' —  ');  // in-flight when HAR was written
  if (status >= 500) return red(`${status}`);
  if (status >= 400) return yellow(`${status}`);
  return green(`${status}`);
}

function hostOf(url: string): string {
  try { return new URL(url).hostname; } catch { return url; }
}

function p(arr: number[], pct: number): number {
  if (arr.length === 0) return 0;
  const sorted = [...arr].sort((a, b) => a - b);
  return sorted[Math.floor(sorted.length * pct)] ?? sorted[sorted.length - 1];
}

// ---- Main ---------------------------------------------------------------

const filePath = process.argv[2] ?? process.env.FILE;
if (!filePath) {
  console.error('Usage: npx tsx scripts/analyze-har.ts <file.har>');
  process.exit(1);
}

const raw = fs.readFileSync(path.resolve(filePath), 'utf8');
const har: HarLog = JSON.parse(raw);
const entries = har.log.entries;

if (entries.length === 0) {
  console.log('No requests in HAR file.');
  process.exit(0);
}

// Compute absolute start times
const startTimes = entries.map(e => new Date(e.startedDateTime).getTime());
const pageStart  = Math.min(...startTimes);

// Enrich entries with absolute timing
interface Entry {
  absStart: number;    // ms since page start
  absEnd:   number;    // ms since page start
  method:   string;
  url:      string;
  status:   number;
  wait:     number;    // TTFB, ms (-1 if unknown)
  receive:  number;    // download time, ms (-1 if unknown)
  total:    number;    // wall clock ms
  error:    string;
  timings:  HarTimings;
}

const enriched: Entry[] = entries.map((e, i) => ({
  absStart: startTimes[i] - pageStart,
  absEnd:   startTimes[i] - pageStart + e.time,
  method:   e.request.method,
  url:      e.request.url,
  status:   e.response.status,
  wait:     e.timings.wait ?? -1,
  receive:  e.timings.receive ?? -1,
  total:    e.time,
  error:    e.response._error ?? '',
  timings:  e.timings,
})).sort((a, b) => a.absStart - b.absStart);

const SLOW_THRESHOLD_MS = 2_000;
const slow    = enriched.filter(e => e.wait >= SLOW_THRESHOLD_MS);
const failed  = enriched.filter(e => e.status === 0 || e.status >= 400);
const aborted = enriched.filter(e => e.status === 0);
const pending = enriched.filter(e => e.status === -1); // in-flight when HAR was written

// ---- Request timeline ---------------------------------------------------

console.log();
console.log(bold(`=== HAR Analysis: ${path.basename(filePath)} ===`));
console.log(dim(`File: ${filePath}`));
console.log(dim(`Captured: ${entries[0].startedDateTime}  |  Total: ${enriched.length} requests`));
console.log();

console.log(bold('REQUEST TIMELINE'));
console.log(dim('  t+ms    Method  Status  Wait     Receive  Total    URL'));
console.log(dim('  ──────  ──────  ──────  ───────  ───────  ───────  ─────────────────────────────────────────────'));

for (const e of enriched) {
  const prefix = e.status === 0
    ? red('✘ ')
    : e.wait >= SLOW_THRESHOLD_MS
    ? yellow('⚠ ')
    : '  ';
  const t = `+${e.absStart.toFixed(0)}ms`.padStart(8);
  const method = e.method.padEnd(6);
  const status = fmtStatus(e.status);
  const wait    = fmtMs(e.wait >= 0 ? e.wait : null).padEnd(8);
  const receive = fmtMs(e.receive >= 0 ? e.receive : null).padEnd(8);
  const total   = fmtMs(e.total).padEnd(8);
  const url = fmtUrl(e.url, 70);
  console.log(`  ${dim(t)}  ${cyan(method)}  ${status}  ${wait} ${receive} ${total} ${prefix}${url}`);
}

// ---- Slow requests ------------------------------------------------------

if (slow.length > 0) {
  console.log();
  console.log(bold(yellow(`SLOW REQUESTS (wait > ${SLOW_THRESHOLD_MS / 1000}s)`)));
  for (const e of slow) {
    const t = e.timings;
    console.log(`  wait=${fmtMs(e.wait)}  receive=${fmtMs(e.receive)}  ${e.method} ${fmtUrl(e.url, 90)}`);
    const breakdown: string[] = [];
    if ((t.blocked ?? -1) >= 0) breakdown.push(`blocked=${fmtMs(t.blocked)}`);
    if ((t.dns    ?? -1) >= 0) breakdown.push(`dns=${fmtMs(t.dns)}`);
    if ((t.connect ?? -1) >= 0) breakdown.push(`connect=${fmtMs(t.connect)}`);
    if ((t.send    ?? -1) >= 0) breakdown.push(`send=${fmtMs(t.send)}`);
    if (breakdown.length) console.log(dim(`    ${breakdown.join('  ')}`));
  }
}

// ---- Failed requests ----------------------------------------------------

if (failed.length > 0) {
  console.log();
  console.log(bold(red(`FAILED REQUESTS (${failed.length})`)));
  for (const e of failed) {
    const err = e.error ? ` [${e.error}]` : '';
    console.log(`  ${fmtStatus(e.status)}  total=${fmtMs(e.total)}  ${e.method} ${fmtUrl(e.url, 85)}${dim(err)}`);
  }
}

// ---- Pending (in-flight when HAR closed) --------------------------------

if (pending.length > 0) {
  console.log();
  console.log(bold(yellow(`PENDING REQUESTS — still in-flight when HAR was written (${pending.length})`)));
  console.log(dim('  These requests had no response within the capture window — likely slow server or connection stall.'));
  for (const e of pending) {
    console.log(`  t+${e.absStart.toFixed(0)}ms  ${e.method} ${fmtUrl(e.url, 90)}`);
  }
}

// ---- Connection saturation detection ------------------------------------

if (aborted.length > 0) {
  // For each aborted request, check if a long in-flight request on the same host
  // overlapped its time window — the classic 6-connection saturation pattern.
  const saturationPairs: Array<{ long: Entry; aborted: Entry }> = [];

  for (const ab of aborted) {
    const abHost = hostOf(ab.url);
    // A "long" request is any non-aborted request that started before the abort
    // and was still in-flight when the abort happened (overlapping window)
    const overlapping = enriched.filter(
      e => e !== ab &&
        !aborted.includes(e) &&
        hostOf(e.url) === abHost &&
        e.absStart <= ab.absStart &&
        e.absEnd   >= ab.absStart &&
        e.total >= 1_000
    );
    for (const long of overlapping) {
      saturationPairs.push({ long, aborted: ab });
    }
  }

  if (saturationPairs.length > 0) {
    console.log();
    console.log(bold(yellow('CONNECTION SATURATION DETECTED')));
    console.log(dim('  Long in-flight requests blocking connections when aborts occurred:'));
    const seen = new Set<string>();
    for (const { long, aborted: ab } of saturationPairs) {
      const key = long.url;
      if (!seen.has(key)) {
        seen.add(key);
        console.log(`  In-flight: ${fmtMs(long.total)} ${cyan(long.method)} ${fmtUrl(long.url, 80)}`);
      }
      console.log(`    → Aborted: ${fmtUrl(ab.url, 80)}`);
    }
    console.log(dim('  Pattern: browser hit 6-connection/host limit. Fix: reduce server-side latency on the long request.'));
  } else {
    console.log();
    console.log(bold(yellow(`ABORTED REQUESTS (${aborted.length}) — no saturation pattern detected`)));
    console.log(dim('  Aborted requests may be browser navigations or cancelled requests.'));
  }
}

// ---- Timing breakdown by host ------------------------------------------

const byHost = new Map<string, Entry[]>();
for (const e of enriched) {
  const h = hostOf(e.url);
  if (!byHost.has(h)) byHost.set(h, []);
  byHost.get(h)!.push(e);
}

if (byHost.size > 1) {
  console.log();
  console.log(bold('BY HOST'));
  for (const [host, reqs] of [...byHost.entries()].sort((a, b) => b[1].length - a[1].length)) {
    const waits = reqs.map(r => r.wait).filter(w => w >= 0);
    const p50w = p(waits, 0.5);
    const p95w = p(waits, 0.95);
    const nFail = reqs.filter(r => r.status === 0 || r.status >= 400).length;
    const failStr = nFail > 0 ? red(` ${nFail} failed`) : '';
    console.log(`  ${host.padEnd(45)} ${String(reqs.length).padStart(3)} reqs  wait p50=${fmtMs(p50w)} p95=${fmtMs(p95w)}${failStr}`);
  }
}

// ---- Summary ------------------------------------------------------------

const allWaits = enriched.map(e => e.wait).filter(w => w >= 0);
const allTotals = enriched.map(e => e.total);
const totalDuration = Math.max(...enriched.map(e => e.absEnd));

console.log();
console.log(bold('SUMMARY'));
const pendingStr = pending.length > 0 ? `  |  ${yellow(`Pending (no response): ${pending.length}`)}` : '';
console.log(`  Requests: ${enriched.length}  |  Failed: ${failed.length}  |  Slow (>${SLOW_THRESHOLD_MS / 1000}s wait): ${slow.length}${pendingStr}`);
console.log(`  Wall-clock span: ${fmtMs(totalDuration)}`);
if (allWaits.length > 0) {
  console.log(`  Wait (TTFB)  — p50: ${fmtMs(p(allWaits, 0.5))}  p95: ${fmtMs(p(allWaits, 0.95))}  max: ${fmtMs(Math.max(...allWaits))}`);
}
console.log(`  Total time   — p50: ${fmtMs(p(allTotals, 0.5))}  p95: ${fmtMs(p(allTotals, 0.95))}  max: ${fmtMs(Math.max(...allTotals))}`);
if (slow.length > 0) {
  const slowest = slow.reduce((a, b) => a.wait > b.wait ? a : b);
  console.log(`  Slowest req:  wait=${fmtMs(slowest.wait)}  ${slowest.method} ${fmtUrl(slowest.url, 70)}`);
}
console.log();

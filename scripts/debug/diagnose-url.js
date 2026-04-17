#!/usr/bin/env node
import { chromium } from 'playwright';
import { writeFileSync, mkdirSync } from 'fs';
import { resolve, join } from 'path';

const args = process.argv.slice(2);
const url = args.find((a) => !a.startsWith('--'));
const captureHar = args.includes('--har');
const outIdx = args.indexOf('--out');
const outDir = outIdx !== -1
  ? resolve(args[outIdx + 1])
  : resolve(`diagnostic-${new Date().toISOString().replace(/[:.]/g, '-')}`);

if (!url) {
  console.error('Usage: node diagnose-url.js <url> [--har] [--out <dir>]');
  process.exit(1);
}

mkdirSync(outDir, { recursive: true });
const browser = await chromium.launch();
const context = await browser.newContext({
  recordHar: captureHar ? { path: join(outDir, 'trace.har'), mode: 'full' } : undefined,
  viewport: { width: 1280, height: 800 },
});
const page = await context.newPage();

const consoleMessages = [];
const failedRequests = [];
const allRequests = [];

page.on('console', (msg) => consoleMessages.push({ type: msg.type(), text: msg.text(), location: msg.location() }));
page.on('pageerror', (err) => consoleMessages.push({ type: 'pageerror', text: err.message, stack: err.stack }));
page.on('requestfailed', (req) => failedRequests.push({ url: req.url(), method: req.method(), failure: req.failure()?.errorText }));
page.on('response', (res) => { if (res.status() >= 400) allRequests.push({ url: res.url(), status: res.status(), method: res.request().method() }); });

const startTime = Date.now();
try { await page.goto(url, { waitUntil: 'networkidle', timeout: 30_000 }); } catch (err) { /* navigation warning */ }
await page.waitForTimeout(2000);
await page.screenshot({ path: join(outDir, 'screenshot.png'), fullPage: true });
if (captureHar) await context.close();
await browser.close();

const errors = consoleMessages.filter((m) => m.type === 'error' || m.type === 'pageerror');
const report = {
  url, timestamp: new Date().toISOString(), loadTimeMs: Date.now() - startTime,
  summary: { consoleErrors: errors.length, failedRequests: failedRequests.length, httpErrors: allRequests.length },
  consoleErrors: errors, failedRequests, httpErrors: allRequests,
};
writeFileSync(join(outDir, 'report.json'), JSON.stringify(report, null, 2));
console.log(`Files written to: ${outDir}`);

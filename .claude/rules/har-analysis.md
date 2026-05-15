# HAR File Analysis

## When to use HAR vs structured logs

**Use HAR for:** client-side network issues — slow API calls from the browser, browser connection limits, ERR_ABORTED, request ordering.

**Use structured logs + traces for:** server-side latency. If HAR shows large `wait` time, the server is slow. Switch to logs/traces; HAR cannot tell you which phase of the request was slow, but structured logs can.

## Run the tool first

If the project has a HAR analyzer (typically `make analyze-har FILE=...` or `npx tsx scripts/analyze-har.ts`), run it before reading any code. The HAR is ground truth for what happened on the wire.

If the project doesn't have one yet, copy `scripts/analyze-har.ts` from the agent-dev-harness repo and add a Makefile target. The script formats a request timeline showing timing, status, errors, and connection-saturation signals.

## What to look for in the output

| Signal | What it means |
|--------|---------------|
| Large `wait` time, small `receive` time | Server-side processing is slow (not network) |
| `ERR_ABORTED` on requests to same host | Browser hit per-host connection limit (usually 6) while another request was in-flight |
| `ERR_NETWORK_IO_SUSPENDED` | Browser tab went idle / throttled while waiting |
| Requests starting many seconds after page load | Connection starvation — first wave blocked subsequent waves |
| `status: 0` with long duration | Request never got a response — timeout or abort |

## Interpreting wait vs receive

- `wait` = time until first byte from server (server processing + queuing)
- `receive` = time to download the response body

If `wait` is large and `receive` is small → server-side problem. Check application code (slow query, slow LLM call, slow upstream API), database query plans (`EXPLAIN ANALYZE`), or connection pool saturation.

If `receive` is large and `wait` is small → payload size or network problem. Check response sizes, gzip/brotli configuration, CDN behavior.

## Connection saturation pattern

If you see:
- One long-running request (e.g. a slow GraphQL query)
- Several requests to the same host that abort at approximately the same time the long request finishes

…the browser's 6-connection-per-host limit was exhausted. The fix is usually on the **server side** (make the slow request faster) rather than client side (parallelizing more requests just makes the saturation worse).

## Save key findings

Capture critical HAR findings in your beads notes before investigating code:

```bash
bd update <id> --notes="HAR: <endpoint> wait=Xs, N tile ERR_ABORTED at Ts mark"
```

This prevents a later session from re-running the same analysis from scratch.

# Job Queue — Transactional Send

When a route both writes to the database AND enqueues a background job describing that write, the enqueue MUST happen inside the same database transaction as the write. Otherwise a crash between `COMMIT` and `enqueue()` leaves the DB updated with no job to process it — a silent data-divergence bug that's only visible to operators after-the-fact.

## The pattern (pg-boss example)

pg-boss's `boss.send` accepts a `db` adapter that wraps a `PoolClient`. Use it to bind the send to your existing transaction:

```typescript
function pgBossDb(client: PoolClient): PgBoss.Db {
  return {
    executeSql: (text: string, values: any[]) => client.query(text, values),
  };
}

await client.query('BEGIN');
// ... DB writes via client ...
await boss.send(jobName, data, { db: pgBossDb(client) });
await client.query('COMMIT');
```

If `boss.send` fails, the transaction rolls back: no DB write, no orphan job. If `COMMIT` fails, both go away together.

## When the queue doesn't support transactional send

For job queues that lack a transaction-binding API (older pg-boss versions, SQS, RabbitMQ, etc.), use the **outbox pattern**: write to an `outbox` table inside the transaction, and have a separate worker poll the outbox and forward to the queue. The worker's "is this row already published" check makes the operation at-least-once safe.

## Where to put the helper

Inline at the first call site is fine. Once a second route needs it, extract to a shared `db/queue.ts` module — don't copy-paste, since a bug in the wrapper is then in two places.

## Symptoms of getting this wrong

- Records exist in DB but never appear in queue/processing logs
- Customer reports "I clicked the button, the page said success, nothing happened"
- Reconciliation jobs find DB rows with no corresponding queue job

These are silent in test environments because crashes between COMMIT and send are rare-but-real in prod. The fix is structural, not "add error handling."

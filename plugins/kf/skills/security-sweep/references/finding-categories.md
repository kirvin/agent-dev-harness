# Security Finding Categories

Seven categories used in every security sweep. Each entry includes the definition,
detection signals, and a bad/good example pair.

---

## CRED — Credential Exposure

**Definition:** Credentials, tokens, keys, or passwords present in source code, logs, or
output where they could be read by an unauthorized party.

**Detection signals:**
- String matching: `api_key`, `secret`, `token`, `password`, `private_key` followed by a value
- `.env` files staged or committed
- Base64-encoded strings in source (potential encoded secrets)
- Values matching known token formats (e.g., `ghp_`, `figd_`, `AKIA`)

**Bad:**
```javascript
const figmaToken = "figd_abc123xyz";  // hardcoded in source
```

**Good:**
```javascript
const figmaToken = process.env.FIGMA_API_TOKEN;
if (!figmaToken) throw new Error("FIGMA_API_TOKEN not set");
```

---

## AUTH — Authentication / Authorization

**Definition:** Missing, bypassable, or incorrectly implemented authentication or
authorization checks.

**Detection signals:**
- Route handlers with no auth middleware
- Auth checks only on the happy path (missing error path, admin path, etc.)
- `req.user` or `req.session` used without null check
- Privilege checks based on user-supplied parameters without server-side verification

**Bad:**
```javascript
app.get('/admin/users', (req, res) => {
  if (req.query.admin === 'true') {  // user controls this
    return db.getAllUsers();
  }
});
```

**Good:**
```javascript
app.get('/admin/users', requireAuth, requireRole('admin'), (req, res) => {
  return db.getAllUsers();
});
```

---

## INJECT — Injection

**Definition:** User-supplied input passed unsanitized into queries, commands, templates,
or other interpreted contexts.

**Detection signals:**
- String concatenation in SQL queries
- `exec`, `spawn`, `execSync` with user-supplied arguments
- Template literals that include `req.body`, `req.query`, or `req.params` without sanitization
- `innerHTML`, `dangerouslySetInnerHTML`, `eval` with external input

**Bad:**
```javascript
const result = await db.query(`SELECT * FROM users WHERE name = '${req.body.name}'`);
```

**Good:**
```javascript
const result = await db.query('SELECT * FROM users WHERE name = $1', [req.body.name]);
```

---

## EXPOSE — Information Disclosure

**Definition:** Sensitive data (credentials, PII, internal paths, stack traces) returned
to callers or written to logs where it shouldn't be.

**Detection signals:**
- `console.log` / `logger.debug` calls with `req.body`, `credentials`, or error objects
- Error handlers that return `err.stack` or `err.message` to HTTP responses
- API responses that include more fields than the client needs
- Log lines containing email addresses or user IDs in plaintext

**Bad:**
```javascript
app.use((err, req, res, next) => {
  res.status(500).json({ error: err.stack });  // exposes internals
});
```

**Good:**
```javascript
app.use((err, req, res, next) => {
  logger.error({ err }, 'Unhandled error');     // logs detail server-side
  res.status(500).json({ error: 'Internal server error' });  // safe to client
});
```

---

## SUPPLY — Supply Chain

**Definition:** Unverified, mutable, or potentially malicious external dependencies
(npm packages, GitHub Actions, Homebrew formulae).

**Detection signals:**
- GitHub Actions `uses:` with version tag instead of SHA
- npm packages with no repository URL or very low download counts
- `npm install <package>` without auditing (`npm audit`)
- Brewfile formulae without fully-qualified tap names
- Package lockfile not committed (or not updated after install)

**Bad:**
```yaml
- uses: actions/checkout@v4   # mutable tag
```

**Good:**
```yaml
- uses: actions/checkout@34e114876b0b11c390a56381ad16ebd13914f8d5  # v4
```

---

## SCOPE — Excessive Privilege

**Definition:** IAM roles, API tokens, or OAuth scopes granted more permissions than the
component actually needs.

**Detection signals:**
- IAM policies with `"Action": "*"` or `"Resource": "*"`
- GitHub tokens with `repo` scope when only `read:repo` is needed
- API integrations requesting write access when they only read
- AWS credentials with `AdministratorAccess` used for routine operations

**Bad:**
```json
{
  "Effect": "Allow",
  "Action": "s3:*",
  "Resource": "*"
}
```

**Good:**
```json
{
  "Effect": "Allow",
  "Action": ["s3:GetObject", "s3:PutObject"],
  "Resource": "arn:aws:s3:::my-bucket/*"
}
```

---

## CI — CI/CD Pipeline

**Definition:** GitHub Actions workflow configuration that exposes secrets, uses unsafe
triggers, or lacks minimum permission declarations.

**Detection signals:**
- Missing `permissions:` key (defaults to write-all)
- `pull_request_target` trigger with code checkout from the PR branch
- `run:` steps that echo or print secret values
- `--verbose` or `--debug` flags that may expand secrets
- `workflow_dispatch` with inputs that flow into `run:` without sanitization

**Bad:**
```yaml
on: pull_request_target
jobs:
  build:
    steps:
      - uses: actions/checkout@SHA
        with:
          ref: ${{ github.event.pull_request.head.sha }}  # untrusted code
      - run: npm test
        env:
          API_KEY: ${{ secrets.API_KEY }}  # exposed to untrusted code
```

**Good:**
```yaml
on: pull_request
permissions:
  contents: read
jobs:
  build:
    steps:
      - uses: actions/checkout@SHA
      - run: npm test
```

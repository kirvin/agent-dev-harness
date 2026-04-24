# Security Requirements (EARS Invariants)

Pre-written EARS invariants covering the five core security domains for this stack.
Copy relevant invariants into `docs/ears/<domain>.md` for your project.

These are the baseline — add feature-specific invariants on top.

---

## Domain 1: Credential Management

```
The system SHALL NOT hardcode credentials, tokens, or secrets in source files.

The system SHALL source all credentials from environment variables or a secrets manager.

The system SHALL NOT log credential values; it SHALL log only whether a credential is present or absent.

The system SHALL NOT pass secrets as command-line arguments.

WHEN a credential is discovered in git history, the system operator SHALL rotate it immediately and treat it as compromised.
```

---

## Domain 2: Authentication and Authorization

```
The system SHALL authenticate all callers before processing requests that read or modify data.

The system SHALL NOT accept requests with expired or malformed tokens.

The system SHALL enforce the principle of least privilege for all service accounts and IAM roles.

WHEN a session token expires, the system SHALL require re-authentication rather than silently extending the session.

The system SHALL NOT elevate privileges based on user-supplied input alone.
```

---

## Domain 3: Data Handling

```
The system SHALL validate and sanitize all user-supplied input before using it in queries, commands, or external API calls.

The system SHALL NOT include sensitive data (credentials, PII, internal paths) in error messages returned to callers.

The system SHALL use parameterized queries or prepared statements for all database operations that include user input.

The system SHALL NOT store credentials in browser storage, logs, or any unencrypted persistent store.
```

---

## Domain 4: Supply Chain

```
The system SHALL pin all GitHub Actions workflow steps to full commit SHAs.

The system SHALL maintain a lockfile for all package managers and commit it to source control.

WHEN adding a new npm dependency, the system operator SHALL verify the package origin and check for known CVEs before merging.

The system SHALL NOT use `latest` or mutable version tags for any dependency in CI/CD pipelines.
```

---

## Domain 5: CI/CD Pipeline

```
GitHub Actions workflows SHALL declare explicit minimum permissions using the `permissions` key.

GitHub Actions workflows SHALL NOT use `permissions: write-all` or omit the `permissions` key.

The system SHALL NOT print secret values in CI log output, including via debug or verbose flags.

WHEN a CI workflow is modified, the change SHALL be reviewed for new secret exposure vectors before merge.

The system SHALL NOT use `pull_request_target` with code checkout from the PR branch unless the workflow is explicitly hardened for untrusted input.
```

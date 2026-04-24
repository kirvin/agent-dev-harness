# Figma Integration

Optional. Enables the `kf:figma-to-spec` skill to work from a Figma design URL.

Most projects don't need this. Set it up only when you're building features
directly from Figma designs.

## What it enables

The `kf:figma-to-spec` skill converts a Figma design URL into a structured feature spec
(user stories, acceptance criteria, implementation notes). Without a token, the skill
falls back to asking you to describe the design manually — it still works, just with
more friction.

## Setup

### 1. Get a Figma personal access token

1. Open Figma in a browser
2. Go to **Settings → Account → Personal access tokens**
3. Click **Generate new token**
4. Give it a name (e.g., `claude-code-local`) and copy the value — it won't be shown again

### 2. Add to your environment

```bash
# In your project's .env.local (gitignored — never .env if that's committed)
FIGMA_API_TOKEN=figd_your_token_here
```

Or let `setup.sh` prompt you during project setup — it asks whether to configure
Figma and writes the token to `.env.local` if you say yes.

### 3. Verify it's available to Claude Code

The token is read from `.claude/settings.local.json` (written by `install-to-project.sh`
or `setup.sh`). To check:

```bash
cat .claude/settings.local.json | grep FIGMA
```

## Usage

Once configured, share a Figma URL in conversation. The `design-skills` rule will
automatically trigger `kf:figma-to-spec` when it detects a Figma URL.

Or activate it directly:
```
Use kf:figma-to-spec on https://www.figma.com/design/...
```

## Notes

- The token provides read-only access to your Figma files
- Never commit a real token — use `.env.local` which is gitignored
- If you rotate the token in Figma, update `.env.local` and re-run `./scripts/setup.sh`

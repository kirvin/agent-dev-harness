# Environment Variables

When adding, removing, or renaming a `VITE_*` or other build-time environment variable in any app:

1. **Check the build pipeline.** Whatever workflow does the production build (e.g. `.github/workflows/deploy-prod.yml`) must pass all required `VITE_*` vars to the `npm run build` command. Vite bakes these in at compile time; missing vars silently fall back to hardcoded defaults (often `localhost`). The result is a deploy that looks healthy but talks to the wrong backend.

2. **Check infra.** Scan whatever IaC the project uses (`infra/`, `terraform/`, etc.) for references to the variable. SSM parameters, ECS task definitions, secrets, and outputs may all need updating.

3. **Update `.env.example`.** Document the correct prod value or where it comes from (SSM path, derived from another var, etc.). Never commit real values.

4. **Check all apps.** A var added to one app may be needed by another. Search the whole apps tree, not just the file you're editing.

## How prod vars are typically injected (frontend)

Static frontends (React + Vite) bake env vars at build time. For these, vars must be present in the deploy job at the moment `npm run build` runs. Common sources:
- AWS SSM parameters (read with `aws ssm get-parameter` in the workflow)
- Derived from other vars (e.g. `VITE_GATEWAY_URL=${BASE_URL}/graphql`)

## How prod vars are typically injected (backend)

Backend services on container orchestrators (ECS, k8s) receive vars via task / pod environment blocks defined in the IaC layer. Editing the IaC + applying is the canonical path; never edit the running task definition by hand.

## Project-specific runbook

Each consuming project should add a brief section here listing:
- Where the production build pipeline reads env vars from
- Where backend env vars are defined in IaC
- Which `VITE_*` vars currently exist + their sources

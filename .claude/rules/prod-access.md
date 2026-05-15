# Production Access — AWS-Deployed Projects

For projects whose production runs on AWS (ECS, EKS, EC2), prefer SSM Session Manager + ECS Exec over SSH/bastion approaches. SSM avoids public-IP exposure, key rotation pain, and the bastion-host attack surface.

This rule applies to projects whose deployment uses AWS. Skip it for non-AWS projects.

## Canonical access path

```bash
# Open an interactive shell on a running ECS task
aws ecs execute-command \
  --cluster <cluster> \
  --task <task-id> \
  --container <container> \
  --command "/bin/bash" \
  --interactive

# Forward a private RDS endpoint to localhost via SSM
aws ssm start-session \
  --target ecs:<cluster>_<task-id>_<runtime-id> \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters "{\"host\":[\"<rds-endpoint>\"],\"portNumber\":[\"5432\"],\"localPortNumber\":[\"5432\"]}"
```

Wrap these as `make prod-shell` and `make prod-tunnel` so the parameters live in one place.

## Prerequisites

- `session-manager-plugin` installed locally (`./scripts/setup.sh` should install it)
- ECS task definitions must enable `executeCommand: true` (set in IaC)
- Task IAM role needs `ssmmessages:*` permissions (managed via `AmazonSSMManagedInstanceCore` or equivalent inline policy)
- Local IAM user/role needs `ssm:StartSession`, `ecs:ExecuteCommand`

## IAM scope hygiene

- Use a least-privilege role for routine prod access — read-only DB user for `prod-tunnel`, `ssm:StartSession` only for the cluster you need.
- Operator MFA on every production access path.
- Audit logs (CloudTrail + ECS Exec session logs) MUST be enabled and shipped to a separate account.

## What NOT to do

- Don't open SSH on prod instances "just for now"
- Don't put a bastion host on a public subnet
- Don't share long-lived AWS access keys for prod access — use SSO + assumed roles
- Don't `aws ec2 describe-instances` and SSH to the public IP — SSM Session Manager works without a public IP at all

## Project-specific runbook

Each consuming project should add a section here listing:
- Cluster names + service names for each environment
- IAM role names used for `prod-tunnel` / `prod-shell`
- The `make` target wrappers that invoke the canonical commands

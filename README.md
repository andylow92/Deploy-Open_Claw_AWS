# Deploy OpenClaw + Ollama on AWS (Private App Access)

This repository provisions AWS infrastructure with Terraform and configures an EC2 host with Ansible to run OpenClaw and Ollama.

The target operating model is:
- SSH limited to explicitly allowed source CIDRs.
- No direct public ingress to OpenClaw/Ollama application endpoints.
- Service health validation after each deployment.
- Policy-as-code checks before Terraform apply.

## Repository layout

- `terraform/`: infrastructure provisioning.
- `ansible/`: host configuration and service deployment.
- `scripts/`: helper scripts for inventory generation and deployment.
- `docs/runbooks/`: operational runbooks (deployment, validation, policy checks, teardown/recovery, and patching guidance).

## 1) Prerequisites and tool versions

Install these tools before running any workflow:

- Terraform `~> 1.5` or newer compatible release.
- Ansible `>= 2.15`.
- `jq` (required by `scripts/generate_inventory.sh`).
- AWS CLI v2 (recommended for credential/profile management).
- OpenSSH client.
- Optional but recommended:
  - Conftest (for policy-as-code checks).

Quick version checks:

```bash
terraform version
ansible --version
jq --version
aws --version
ssh -V
```

## 2) Configure deployment inputs

1. Copy and edit Terraform variables:

   ```bash
   cp terraform/terraform.tfvars.example terraform/terraform.tfvars
   ```

2. In `terraform/terraform.tfvars`, set at least:
   - `ssh_ingress_cidrs` to your fixed source CIDR(s) (prefer `/32` where possible).
   - `key_name` or `public_key_path` for SSH key handling.
   - Environment-specific values (`aws_region`, subnet CIDRs, instance sizing).

3. Export or configure AWS credentials (profile or environment variables).

## 3) End-to-end deployment (Terraform then Ansible)

### Step A — Provision infrastructure

```bash
terraform -chdir=terraform init
terraform -chdir=terraform fmt -check
terraform -chdir=terraform validate
terraform -chdir=terraform plan -out tfplan
terraform -chdir=terraform apply tfplan
```

### Step B — Generate inventory from Terraform outputs

```bash
./scripts/generate_inventory.sh
```

By default this writes `ansible/inventory/hosts.ini` using `terraform output -json` and values like `ansible_host`, `ssh_user`, and `instance_id`.

### Step C — Configure host and deploy services

```bash
ansible-playbook -i ansible/inventory/hosts.ini ansible/playbooks/site.yml
```

Or run the helper wrapper (inventory generation + playbook):

```bash
./scripts/deploy.sh
```

## 4) Validation checklist (post-deploy)

Use this checklist after every deployment:

1. SSH works only from allowed CIDR.
2. No public app endpoints are reachable for OpenClaw/Ollama.
3. OpenClaw and Ollama services are healthy.

Detailed validation commands are documented in:
- `docs/runbooks/validation-checklist.md`

## 5) Policy-as-code workflow

Run policy checks before Terraform apply:

- Local Conftest workflow.
- Understanding and triaging `deny` messages.

See:
- `docs/runbooks/policy-as-code.md`

## 6) Teardown and recovery procedures

For controlled destruction, incident recovery, and rehydration:

- `docs/runbooks/teardown-and-recovery.md`

## 7) Update and patch management guidance

For OS, container, and dependency patching cadence:

- `docs/runbooks/update-and-patch-management.md`

## Notes on security defaults

Current Terraform security group rules allow SSH plus ports 80/443 ingress. OpenClaw/Ollama ports should remain non-public, and you should enforce this through policy checks and validation. If 80/443 are not required in your environment, remove or restrict them in Terraform.

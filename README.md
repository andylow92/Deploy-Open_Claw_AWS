# Deploy OpenClaw + Ollama on AWS

This repository provisions an AWS EC2 host and configures it to run [OpenClaw](https://github.com/openclaw/openclaw) alongside a local [Ollama](https://ollama.com) inference service. Infrastructure is defined with **Terraform**, host configuration is driven by **Ansible**, and security guardrails are enforced with **Conftest (OPA/Rego)**, **tfsec**, and **Checkov**.

Both services are bound to the loopback interface by default — there are no public application endpoints. Access to the host is via SSH from a restricted CIDR (or via AWS SSM when `enable_ssm = true`).

---

## Table of contents

1. [Architecture](#architecture)
2. [Repository layout](#repository-layout)
3. [Prerequisites](#prerequisites)
4. [AWS authentication](#aws-authentication)
5. [Configuration](#configuration)
   - [Terraform variables](#terraform-variables)
   - [Environment tfvars files](#environment-tfvars-files)
   - [Ansible role variables](#ansible-role-variables)
6. [Deployment](#deployment)
   - [1. Clone and bootstrap](#1-clone-and-bootstrap)
   - [2. Terraform plan + policy checks](#2-terraform-plan--policy-checks)
   - [3. Terraform apply](#3-terraform-apply)
   - [4. Generate Ansible inventory](#4-generate-ansible-inventory)
   - [5. Run Ansible](#5-run-ansible)
7. [Validation](#validation)
8. [Day-2 operations](#day-2-operations)
9. [Teardown](#teardown)
10. [CI/CD](#cicd)
11. [Troubleshooting](#troubleshooting)

---

## Architecture

- **Terraform (`terraform/`)** — provisions AWS resources through reusable modules:
  - `modules/network`: VPC, public/private subnets, IGW, optional NAT gateway, route tables.
  - `modules/security`: security groups with restricted SSH ingress and controlled egress.
  - `modules/compute`: EC2 instance (Ubuntu 22.04 by default), EBS volume, IAM instance profile, optional SSM + CloudWatch agent hooks.
- **Ansible (`ansible/`)** — configures the host:
  - `common`: OS hardening, `ufw`, `fail2ban`, SSHD tightening.
  - `docker`: Docker engine + compose plugin.
  - `ollama`: installs pinned Ollama, systemd unit, loopback bind.
  - `openclaw`: pulls OpenClaw, runs it under Docker pointing at local Ollama.
- **Policy (`policy/conftest/`)** — Rego policies executed with Conftest against the Terraform plan JSON (security, network, compute checks).
- **Scripts (`scripts/`)** — thin wrappers for the end-to-end flow.

## Repository layout

```text
terraform/
  providers.tf  versions.tf  main.tf  variables.tf  outputs.tf
  terraform.tfvars.example
  modules/{network,security,compute}/
  environments/{dev,prod}/terraform.tfvars
ansible/
  playbooks/site.yml
  inventory/hosts.ini          # generated, do not edit
  roles/{common,docker,ollama,openclaw}/
policy/conftest/
  main.rego
  policy/security.rego         # --policy root used by CI and run_conftest.sh
  terraform/{security,network,compute}.rego
  tests/security_test.rego
scripts/
  export_plan.sh               # terraform init+plan, export tfplan.json
  export_tf_plan_json.sh       # plan without backend (for CI/local gating)
  run_conftest.sh              # run Conftest against a target
  generate_inventory.sh        # build ansible/inventory/hosts.ini from TF outputs
  deploy.sh                    # generate inventory + run site.yml
docs/runbooks/                 # policy-as-code, validation, patching, teardown
.github/workflows/policy-ci.yml
```

---

## Prerequisites

Install these on the workstation running the deployment:

| Tool | Minimum version | Purpose |
|------|-----------------|---------|
| Terraform | 1.8.x | IaC |
| AWS CLI | 2.x | Authentication, SSM |
| Ansible | 2.14+ | Host configuration |
| Python | 3.10+ | Ansible runtime |
| `jq` | 1.6+ | Parse Terraform JSON output |
| Conftest | 0.58.0+ | Policy checks |
| OpenSSH client | any | Reach the instance |
| Git | any | Clone |

Optional (matches CI): `tfsec`, `checkov`.

You also need:

- An AWS account and IAM identity with permissions to create VPC, EC2, IAM, CloudWatch Logs, and (if enabled) SSM resources.
- An SSH keypair. Either provide the public key path via `public_key_path` (Terraform creates the AWS key pair for you) or reference an existing key pair with `ssh_key_name`.
- The public IP/CIDR of your workstation or bastion — this is what you will put in `ssh_ingress_cidrs`. `0.0.0.0/0` is rejected by validation.

## AWS authentication

Use any method the AWS provider supports. Examples:

```bash
# Static creds (short sessions only)
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
export AWS_SESSION_TOKEN=...
export AWS_REGION=us-east-1

# Or an SSO/named profile
export AWS_PROFILE=my-profile
export AWS_REGION=us-east-1

aws sts get-caller-identity
```

---

## Configuration

### Terraform variables

All variables are defined in `terraform/variables.tf`. The most important ones:

**Identity / region**

| Variable | Default | Notes |
|----------|---------|-------|
| `project_name` | `openclaw` | Tag and name prefix. |
| `environment` | `dev` | Appended to `name_prefix`. |
| `aws_region` | `us-east-1` | |
| `owner` | `platform` | Propagated as `Owner` tag. |

**Network**

| Variable | Default | Notes |
|----------|---------|-------|
| `vpc_cidr` | `10.42.0.0/16` | |
| `public_subnet_cidrs` | `["10.42.1.0/24"]` | Must fit in `availability_zones`. |
| `private_subnet_cidrs` | `["10.42.11.0/24"]` | |
| `availability_zones` | `["us-east-1a"]` | |
| `enable_nat_gateway` | `false` | Enable for private subnet egress. |

**Access**

| Variable | Default | Notes |
|----------|---------|-------|
| `ssh_ingress_cidrs` | `["203.0.113.0/24"]` | Required; `0.0.0.0/0` rejected. Set to your workstation IP `/32`. |
| `ssh_key_name` | `""` | Use an existing AWS key pair. |
| `public_key_path` | `""` | If `ssh_key_name` is empty, a key pair is created from this public key. |
| `ssh_user` | `ubuntu` | Used by Ansible inventory. |
| `instance_egress_policies` | HTTPS/HTTP/DNS only | Controlled outbound rules; extend if repos/mirrors need more. |

**Compute**

| Variable | Default | Notes |
|----------|---------|-------|
| `instance_type` | `t3.large` | |
| `ami_id` | `""` | Leave blank to use latest Ubuntu 22.04 LTS. |
| `root_volume_size_gb` | `100` | Minimum 20. |
| `instance_profile_name` | `""` | Provide to reuse an existing profile. |
| `enable_ssm` | `true` | Attaches `AmazonSSMManagedInstanceCore`. |
| `enable_cloudwatch_agent` | `false` | |
| `ssm_preferred_access` | `false` | When true, no SSH key is attached. |
| `additional_user_data` | `""` | Extra cloud-init snippet. |

**Services** (consumed by Ansible via Terraform outputs or explicit overrides)

| Variable | Default | Notes |
|----------|---------|-------|
| `openclaw_repo_url` | `""` | Override if mirroring. |
| `openclaw_repo_ref` | `main` | Branch/tag/commit. |
| `ollama_version` | `latest` | Pin to a release tag for reproducibility. |
| `ollama_model` | `""` | Initial model to pull. |
| `ollama_bind_host` | `127.0.0.1` | Keep loopback. |
| `ollama_port` | `11434` | |

**Ops**

| Variable | Default |
|----------|---------|
| `enable_logging` | `true` |
| `log_retention_days` | `30` |
| `enable_monitoring` | `true` |
| `metrics_retention_days` | `15` |

See `terraform/terraform.tfvars.example` for a copy-pasteable starting point.

### Environment tfvars files

Committed example values per environment live under `terraform/environments/<env>/terraform.tfvars`. Pass one with `-var-file`:

```bash
terraform -chdir=terraform plan \
  -var-file=environments/dev/terraform.tfvars \
  -var='ssh_ingress_cidrs=["YOUR.PUBLIC.IP/32"]' \
  -var='public_key_path=~/.ssh/id_ed25519.pub'
```

A root-level `terraform/terraform.tfvars` is git-ignored — use it for secrets or machine-specific overrides.

### Ansible role variables

Defaults live under `ansible/roles/<role>/defaults/main.yml`. Override per host/group in `ansible/inventory/` or via `-e`.

| Role | Variable | Default |
|------|----------|---------|
| common | `common_enable_ufw` | `true` |
| common | `common_enable_fail2ban` | `true` |
| common | `common_sshd_settings.PermitRootLogin` | `no` |
| common | `common_sshd_settings.PasswordAuthentication` | `no` |
| docker | `docker_users` | `[ubuntu]` |
| ollama | `ollama_version` | `0.9.7` |
| ollama | `ollama_bind_host` | `127.0.0.1` |
| ollama | `ollama_bind_port` | `11434` |
| ollama | `ollama_models` | `[]` |
| ollama | `ollama_install_script_url` | pinned to release tag |
| ollama | `ollama_install_script_sha256` | `""` (set to enforce) |
| openclaw | `openclaw_repo_url` | `https://github.com/openclaw/openclaw.git` |
| openclaw | `openclaw_repo_ref` | `main` |
| openclaw | `openclaw_install_dir` | `/opt/openclaw` |
| openclaw | `openclaw_run_with_docker` | `true` |
| openclaw | `openclaw_ollama_endpoint` | `http://127.0.0.1:11434` |
| openclaw | `openclaw_healthcheck_url` | `http://127.0.0.1:3000/health` |
| openclaw | `openclaw_env` | `{}` |

---

## Deployment

### 1. Clone and bootstrap

```bash
git clone https://github.com/andylow92/deploy-open_claw_aws.git
cd deploy-open_claw_aws

# Pick an environment
export TF_VAR_FILE=environments/dev/terraform.tfvars

# AWS creds (choose one; see "AWS authentication")
export AWS_PROFILE=my-profile
export AWS_REGION=us-east-1
```

### 2. Terraform plan + policy checks

Produce the plan JSON that the policy pipeline consumes:

```bash
./scripts/export_plan.sh
# -> terraform/tfplan and terraform/tfplan.json
```

`export_plan.sh` runs `terraform init` + `plan` against `terraform/` with no extra vars; to use an environment file, run the commands directly:

```bash
terraform -chdir=terraform init
terraform -chdir=terraform plan \
  -var-file=environments/dev/terraform.tfvars \
  -out=terraform/tfplan
terraform -chdir=terraform show -json terraform/tfplan > terraform/tfplan.json
```

Run the guardrails:

```bash
./scripts/run_conftest.sh terraform/tfplan.json
# Optional (matches CI):
tfsec terraform/
checkov -d terraform/ --framework terraform
```

Fix any `deny` findings and re-plan until clean. See `docs/runbooks/policy-as-code.md` for common violations.

### 3. Terraform apply

```bash
terraform -chdir=terraform apply \
  -var-file=environments/dev/terraform.tfvars terraform/tfplan
```

On success, Terraform outputs include `instance_public_ip`, `instance_id`, and `ssh_user` — used by the inventory generator.

### 4. Generate Ansible inventory

```bash
SSH_KEY_PATH=~/.ssh/id_ed25519 ./scripts/generate_inventory.sh
# -> ansible/inventory/hosts.ini
```

`SSH_KEY_PATH` defaults to `~/.ssh/id_rsa`. The file is regenerated from Terraform outputs on every run; don't hand-edit it.

### 5. Run Ansible

```bash
./scripts/deploy.sh
```

Equivalent to:

```bash
ansible-playbook \
  -i ansible/inventory/hosts.ini \
  ansible/playbooks/site.yml
```

For verbose runs or role overrides:

```bash
ansible-playbook -i ansible/inventory/hosts.ini ansible/playbooks/site.yml \
  -vv \
  -e ollama_models='["llama3.1:8b"]' \
  -e openclaw_repo_ref=v1.0.0
```

---

## Validation

Run the full checklist in `docs/runbooks/validation-checklist.md`. Quick smoke test:

```bash
# SSH from an allowed CIDR succeeds
ssh -i ~/.ssh/id_ed25519 ubuntu@<instance_public_ip>

# On the host
sudo systemctl status ollama openclaw --no-pager
curl -fsS http://127.0.0.1:11434/api/tags
sudo docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'

# From outside the allowed CIDR, app ports should NOT be reachable
nc -vz <instance_public_ip> 11434   # expect refused/timeout
nc -vz <instance_public_ip> 3000    # expect refused/timeout
```

---

## Day-2 operations

- **Patching** — `docs/runbooks/update-and-patch-management.md`.
- **Policy changes** — `docs/runbooks/policy-as-code.md`.
- **Teardown / recovery** — `docs/runbooks/teardown-and-recovery.md`.

Access without SSH: with `enable_ssm = true`, connect via:

```bash
aws ssm start-session --target <instance_id>
```

---

## Teardown

```bash
terraform -chdir=terraform plan -destroy \
  -var-file=environments/dev/terraform.tfvars -out destroy.tfplan
terraform -chdir=terraform apply destroy.tfplan

rm -f ansible/inventory/hosts.ini \
      terraform/tfplan terraform/tfplan.json destroy.tfplan
```

---

## CI/CD

`.github/workflows/policy-ci.yml` runs on pull requests and pushes to `main`:

1. `terraform fmt -check -recursive`
2. `terraform init` / `validate`
3. `terraform plan` + JSON export
4. `conftest test tfplan.json --policy policy/conftest/policy`
5. `tfsec` (blocking)
6. `checkov` (blocking, Terraform framework)

The Conftest version is pinned in the workflow. Populate `CONFTEST_SHA256` with the upstream checksum to enforce supply-chain verification.

---

## Troubleshooting

| Symptom | Likely cause / fix |
|---------|--------------------|
| `ssh_ingress_cidrs cannot contain 0.0.0.0/0` | Variable validation — set to your public IP `/32`. |
| `ansible_host output is empty` | `terraform apply` has not run (or failed) — re-run before `generate_inventory.sh`. |
| SSH times out from allowed IP | Your egress IP may differ from what you configured; verify with `curl ifconfig.me` and update `ssh_ingress_cidrs`. |
| Conftest reports missing required tags | Ensure `project_name`, `environment`, `owner` are set. |
| Ansible cannot reach host | Confirm key pair matches `public_key_path`/`ssh_key_name`; confirm `SSH_KEY_PATH` used by `generate_inventory.sh`. |
| Ollama model missing | Set `-e ollama_models='["<model>:<tag>"]'` and re-run the playbook. |
| tfsec/Checkov fails in CI but not locally | Run the same versions locally; see the workflow file for pinned versions. |

# Deploy OpenClaw + Ollama on AWS

This repository provides a clean infrastructure + configuration layout for deploying OpenClaw and Ollama on AWS using Terraform, Ansible, and policy-as-code checks.

## Top-level architecture

- **Terraform (`terraform/`)** provisions cloud resources through reusable modules:
  - `modules/network`: VPC/subnet networking
  - `modules/security`: security groups and ingress controls
  - `modules/compute`: EC2 host(s) for OpenClaw + Ollama
- **Ansible (`ansible/`)** configures the provisioned hosts with common baseline setup plus service-specific roles.
- **Policy (`policy/conftest/`)** enforces baseline guardrails against Terraform plan output with OPA/Conftest.
- **Scripts (`scripts/`)** automate common workflows (plan export, inventory generation, deployment).

## Repository structure

```text
terraform/
  providers.tf
  versions.tf
  main.tf
  variables.tf
  outputs.tf
  modules/
    network/
    security/
    compute/
  environments/
    dev/terraform.tfvars
    prod/terraform.tfvars
ansible/
  playbooks/site.yml
  inventory/
  roles/
    common/
    ollama/
    openclaw/
policy/
  conftest/
    main.rego
    terraform/
      security.rego
      network.rego
      compute.rego
scripts/
README.md
docs/
  runbooks/
```

## Expected deployment flow

1. **Select environment variables** from `terraform/environments/<env>/terraform.tfvars` and adjust values as needed.
2. **Initialize and plan Terraform**, then export the plan JSON for policy checks:
   - `./scripts/export_plan.sh`
3. **Run policy checks** using Conftest against `terraform/tfplan.json`.
4. **Apply Terraform** to create/update AWS infrastructure.
5. **Generate Ansible inventory** from Terraform outputs:
   - `./scripts/generate_inventory.sh`
6. **Configure host(s)** with Ansible:
   - `./scripts/deploy.sh`
7. **Operate and maintain** with documented procedures in `docs/runbooks/`.

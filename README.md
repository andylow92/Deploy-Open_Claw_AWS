# Deploy OpenClaw + Ollama on AWS (Private App Access)

This repository provisions an AWS environment for running OpenClaw and Ollama on an EC2 instance with SSH access restricted by CIDR and **no public ingress** to application ports.

## 1) Architecture

### High-level layout

- A single **VPC** containing at least one subnet used by the EC2 host.
- The EC2 instance runs both OpenClaw and Ollama services.
- A security group controls inbound access.

```text
                        Internet
                            |
                     SSH (22/TCP only)
                 from allowed_ssh_cidr only
                            |
+----------------------------------------------------------------+
|                              VPC                               |
|                                                                |
|   +-------------------------- Subnet ------------------------+  |
|   |                                                         |  |
|   |  EC2 Instance                                           |  |
|   |  - OpenClaw service (local/private access only)         |  |
|   |  - Ollama service (local/private access only)           |  |
|   |                                                         |  |
|   |  Ingress allowed: 22/TCP from allowed_ssh_cidr         |  |
|   |  Ingress denied: OpenClaw/Ollama public ports           |  |
|   +---------------------------------------------------------+  |
|                                                                |
+----------------------------------------------------------------+
```

### Ingress model

- **SSH access** is limited to `allowed_ssh_cidr`.
- **No public ingress** is exposed for OpenClaw/Ollama service ports.
- App access should occur only locally on the instance, through private networking, or via explicit secure tunneling if needed.

## 2) Prerequisites

- **Terraform**: use a current, team-approved version (recommended: `>= 1.5.x`).
- **Ansible**: use a current stable release (recommended: `>= 2.15`).
- **AWS account credentials** configured locally (for example via AWS CLI profiles or environment variables).
- IAM principal used for deployment should have permissions for resources managed by this stack, typically including:
  - VPC/networking (VPC, subnets, route tables, security groups)
  - EC2 instances, key pair usage, and related metadata
  - IAM actions only if your Terraform configuration creates/updates IAM resources
  - Read/write access to Terraform backend resources (if remote state is used)

## 3) Configuration

1. Copy the example variable file:

   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` and set:

   - `allowed_ssh_cidr` to your fixed public IP/CIDR (for example `203.0.113.10/32`).

3. Review any additional variables (region, instance size, key name, tags, etc.) before provisioning.

## 4) Provisioning workflow

From the repository root:

1. Initialize Terraform:

   ```bash
   terraform init
   ```

2. Review planned changes:

   ```bash
   terraform plan
   ```

3. Apply infrastructure:

   ```bash
   terraform apply
   ```

4. Export required Terraform outputs for Ansible inventory/vars (adjust output names to your module):

   ```bash
   terraform output -json > terraform-outputs.json
   ```

5. Run the Ansible playbook to configure services:

   ```bash
   ansible-playbook -i inventory.ini playbook.yml
   ```

## 5) Verification

After provisioning and configuration:

1. **SSH from allowed IP works**
   - From a client within `allowed_ssh_cidr`, confirm SSH succeeds.

2. **SSH from non-allowed IP is denied**
   - Attempt SSH from a different source IP/CIDR and confirm timeout/denial.

3. **OpenClaw service healthy on instance (local check)**
   - SSH to EC2 and verify service status / local endpoint (for example `curl localhost:<port>/health`).

4. **Ollama service running and model available**
   - On the instance, confirm service is active and list/test model availability (for example with `ollama list` or equivalent health check).

## 6) Security notes

- **No public app ports**: Keeping OpenClaw/Ollama ports private reduces attack surface and prevents unsolicited internet access to inference/application endpoints.
- **Patching and updates**:
  - Regularly patch the EC2 OS and packages.
  - Keep OpenClaw/Ollama and automation dependencies up to date.
  - Rebuild/redeploy on a defined cadence.
- **Keys and IAM hygiene**:
  - Rotate SSH keys and any API credentials regularly.
  - Use least-privilege IAM policies for both humans and automation roles.
  - Prefer short-lived credentials (role assumption) over long-lived static keys.

## 7) Destroy and cleanup

1. Tear down infrastructure:

   ```bash
   terraform destroy
   ```

2. Remove local artifacts that may contain sensitive or environment-specific data, such as:
   - `terraform.tfvars` (if it contains sensitive values)
   - `terraform-outputs.json`
   - local plan files, state backups, or generated inventory files

3. If applicable, revoke temporary credentials and remove no-longer-needed SSH keys.

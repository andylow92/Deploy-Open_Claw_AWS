# Policy-as-Code Runbook (Conftest)

Use Conftest with Rego policies to block insecure Terraform changes before apply.

## 1) Install Conftest locally

macOS (Homebrew):

```bash
brew install conftest
```

Linux (binary):

```bash
CONFTTEST_VERSION=0.59.0
curl -sSL -o conftest.tar.gz \
  "https://github.com/open-policy-agent/conftest/releases/download/v${CONFTTEST_VERSION}/conftest_${CONFTTEST_VERSION}_Linux_x86_64.tar.gz"
tar -xzf conftest.tar.gz conftest
sudo mv conftest /usr/local/bin/
conftest --version
```

## 2) Recommended repo structure for policies

```text
policy/
  terraform/
    security.rego
```

## 3) Run Conftest locally

### Option A — test Terraform HCL directly

```bash
conftest test terraform/**/*.tf -p policy
```

### Option B — test Terraform plan JSON (preferred)

```bash
terraform -chdir=terraform plan -out tfplan
terraform -chdir=terraform show -json tfplan > tfplan.json
conftest test tfplan.json -p policy
```

## 4) Interpreting deny messages

Typical deny output indicates:

- Rule name and policy file.
- Resource path/type.
- Why the change violates policy.

Example classes of denies to enforce:

- SSH ingress CIDR is too broad (for example `0.0.0.0/0`).
- Public ingress exists on OpenClaw/Ollama ports.
- Required tags are missing.
- Unencrypted resources or permissive defaults.

Triage flow:

1. Locate the resource in `terraform plan` output.
2. Confirm if violation is intentional or misconfiguration.
3. Modify Terraform input/module code.
4. Re-run `plan` + `conftest test` until zero denies.

## 5) CI recommendation

Add a pipeline gate that fails on any deny output:

1. `terraform fmt -check`
2. `terraform validate`
3. `terraform plan -out tfplan`
4. `terraform show -json tfplan > tfplan.json`
5. `conftest test tfplan.json -p policy`

Only allow apply when Conftest exits with code `0`.

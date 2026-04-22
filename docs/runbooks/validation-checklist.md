# Validation Checklist Runbook

Run these checks after Terraform + Ansible deployment.

## 1) SSH works only from allowed CIDR

### Positive check (allowed source)
From a workstation/IP included in `ssh_ingress_cidrs`:

```bash
ssh -i ~/.ssh/<key> ubuntu@<instance_public_ip>
```

Expected: successful login.

### Negative check (non-allowed source)
From an IP outside `ssh_ingress_cidrs`, attempt:

```bash
ssh -o ConnectTimeout=10 -i ~/.ssh/<key> ubuntu@<instance_public_ip>
```

Expected: timeout or denied connection.

## 2) No public app endpoints

OpenClaw and Ollama should not be publicly reachable.

From a non-trusted external source, verify target ports are closed/not routable:

```bash
nc -vz <instance_public_ip> 11434
nc -vz <instance_public_ip> 3000
```

Expected: connection refused or timeout.

Also verify no broad security-group ingress to app ports:

```bash
terraform -chdir=terraform state show module.security.aws_security_group.instance
```

Expected: no `0.0.0.0/0` ingress for OpenClaw/Ollama service ports.

## 3) OpenClaw service healthy

SSH to host and run:

```bash
sudo systemctl status openclaw --no-pager
sudo docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
```

Expected: service active and containers healthy/running.

If OpenClaw exposes a local health endpoint in your deployment:

```bash
curl -fsS http://127.0.0.1:<openclaw_port>/health
```

Expected: HTTP 200 or service-specific healthy response.

## 4) Ollama service healthy

SSH to host and run:

```bash
sudo systemctl status ollama --no-pager
curl -fsS http://127.0.0.1:11434/api/tags
ollama list
```

Expected: service active, API responds, and model list available.

## 5) Capture evidence

For operational audit trails, save:

- Terraform apply output (or CI artifact).
- Ansible run output.
- Command output for each checklist item.
- Date/time, operator, environment.

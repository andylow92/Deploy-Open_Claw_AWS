# Teardown and Recovery Runbook

## 1) Controlled teardown

Before destroy:

1. Confirm target workspace/environment.
2. Export any logs or artifacts you need for audit.
3. Confirm no active sessions/jobs on the host.

Run:

```bash
terraform -chdir=terraform plan -destroy -out destroy.tfplan
terraform -chdir=terraform apply destroy.tfplan
```

Then remove local generated artifacts if needed:

```bash
rm -f ansible/inventory/hosts.ini tfplan destroy.tfplan tfplan.json
```

## 2) Recovery from failed configuration

If Terraform succeeded but Ansible failed:

1. Regenerate inventory:

   ```bash
   ./scripts/generate_inventory.sh
   ```

2. Re-run Ansible with verbosity:

   ```bash
   ansible-playbook -i ansible/inventory/hosts.ini ansible/playbooks/site.yml -vv
   ```

3. Validate services with runbook checklist.

## 3) Recovery from instance/service drift

If host is reachable but services are degraded:

1. SSH to host.
2. Collect diagnostics:

   ```bash
   sudo systemctl status openclaw --no-pager
   sudo systemctl status ollama --no-pager
   sudo journalctl -u openclaw -n 200 --no-pager
   sudo journalctl -u ollama -n 200 --no-pager
   sudo docker ps -a
   ```

3. Apply targeted remediations:
   - Restart failed services.
   - Re-run Ansible playbook.
   - If needed, rebuild/redeploy OpenClaw containers.

## 4) Recovery from infrastructure drift or corruption

1. Run:

```bash
terraform -chdir=terraform plan
```

2. If unexpected drift appears:
   - Validate whether drift is legitimate manual change.
   - Reconcile by code (preferred) and re-apply.

3. If recovery-in-place is risky, do immutable replacement:
   - Apply Terraform to create replacement resources.
   - Re-run Ansible on replacement host.
   - Validate and then decommission old host.

## 5) Post-recovery validation

Always re-run full validation checklist:

- SSH restriction behavior.
- No public app endpoints.
- OpenClaw and Ollama health.

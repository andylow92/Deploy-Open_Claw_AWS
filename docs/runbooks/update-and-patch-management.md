# Update and Patch Management Runbook

## 1) Patch cadence

Recommended minimum cadence:

- OS security updates: weekly.
- Docker engine and runtime dependencies: monthly or as critical CVEs emerge.
- OpenClaw and Ollama updates: monthly or per security advisories.
- Terraform/Ansible/Conftest tooling updates: monthly.

For critical vulnerabilities, execute out-of-band patching immediately.

## 2) Patch process

1. Review upstream release notes and CVEs.
2. Create/update a change ticket.
3. Validate changes in non-production environment first.
4. Apply patches:
   - OS packages on host.
   - Re-run Ansible roles if role logic changed.
   - Rebuild/restart OpenClaw containers.
5. Run full validation checklist.

## 3) OS and package update example

On the host:

```bash
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get autoremove -y
sudo reboot
```

After reboot:

```bash
sudo systemctl is-active ollama
sudo systemctl is-active openclaw
```

## 4) OpenClaw and Ollama update guidance

- OpenClaw is deployed from Git via Ansible (`openclaw_repo_url`, branch `main` by default).
- Re-run playbook to pull latest code and re-apply Docker compose deployment.
- For Ollama, re-run role tasks or upstream installer flow as needed.
- Re-validate local endpoint health and model availability.

## 5) Rollback planning

Before patching:

- Snapshot/backup where applicable.
- Preserve previous known-good image/version references.
- Keep Terraform and Ansible state in version control.

Rollback options:

- Re-apply previous Terraform commit and Ansible revision.
- Recreate host from known-good code.
- Restore from snapshots if available.

## 6) Operational records

Track for each patch window:

- Date/time and operator.
- Versions before/after.
- CVEs/remediations addressed.
- Validation outcomes and incident notes.

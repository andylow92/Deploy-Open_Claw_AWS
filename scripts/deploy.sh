#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

"${ROOT_DIR}/scripts/generate_inventory.sh"

ansible-playbook \
  -i "${ROOT_DIR}/ansible/inventory/hosts.ini" \
  "${ROOT_DIR}/ansible/playbooks/site.yml"

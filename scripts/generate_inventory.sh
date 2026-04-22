#!/usr/bin/env bash
set -euo pipefail

TF_DIR=${TF_DIR:-terraform}
OUTPUT_FILE=${OUTPUT_FILE:-ansible/inventory/hosts.ini}
SSH_KEY_PATH=${SSH_KEY_PATH:-~/.ssh/id_rsa}

if ! command -v terraform >/dev/null 2>&1; then
  echo "terraform binary is required" >&2
  exit 1
fi

json_output=$(terraform -chdir="$TF_DIR" output -json)

ansible_host=$(jq -r '.ansible_host.value // empty' <<<"$json_output")
instance_id=$(jq -r '.instance_id.value // empty' <<<"$json_output")
ssh_user=$(jq -r '.ssh_user.value // "ubuntu"' <<<"$json_output")

if [[ -z "$ansible_host" ]]; then
  echo "ansible_host output is empty. Run terraform apply first." >&2
  exit 1
fi

mkdir -p "$(dirname "$OUTPUT_FILE")"
cat > "$OUTPUT_FILE" <<INVENTORY
[openclaw]
openclaw ansible_host=${ansible_host} ansible_user=${ssh_user} ansible_ssh_private_key_file=${SSH_KEY_PATH} instance_id=${instance_id}

[openclaw:vars]
ansible_python_interpreter=/usr/bin/python3
INVENTORY

echo "Inventory written to ${OUTPUT_FILE}"

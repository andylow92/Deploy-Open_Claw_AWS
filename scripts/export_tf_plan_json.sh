#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="${TF_DIR:-${ROOT_DIR}/terraform}"
PLAN_FILE="${PLAN_FILE:-${TF_DIR}/tfplan.binary}"
PLAN_JSON="${PLAN_JSON:-${TF_DIR}/tfplan.json}"

cd "${TF_DIR}"
terraform init -input=false -backend=false
terraform plan -input=false -lock=false -out="${PLAN_FILE}"
terraform show -json "${PLAN_FILE}" > "${PLAN_JSON}"

echo "Terraform plan exported to ${PLAN_JSON}"

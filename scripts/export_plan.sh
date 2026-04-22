#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TF_DIR=${TF_DIR:-"${ROOT_DIR}/terraform"}
PLAN_FILE=${PLAN_FILE:-"${TF_DIR}/tfplan"}
PLAN_JSON=${PLAN_JSON:-"${TF_DIR}/tfplan.json"}

terraform -chdir="${TF_DIR}" init
terraform -chdir="${TF_DIR}" plan -out="${PLAN_FILE}"
terraform -chdir="${TF_DIR}" show -json "${PLAN_FILE}" > "${PLAN_JSON}"

echo "Plan exported to ${PLAN_FILE} and ${PLAN_JSON}"

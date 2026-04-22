#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
POLICY_DIR="${POLICY_DIR:-${ROOT_DIR}/policy/conftest/policy}"

if [[ $# -eq 0 ]]; then
  echo "Usage: $0 <target1> [target2 ...]"
  echo "Example: $0 terraform/tfplan.json"
  exit 1
fi

conftest test "$@" --policy "${POLICY_DIR}" --output table

#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

run_fixture() {
  local name="$1"
  local tfvars_file="$2"
  local expect_fail="$3"
  local fixture_dir="${ROOT_DIR}/tests/guardrails/${name}"

  echo "==> Running guardrail fixture: ${name} (${tfvars_file})"
  terraform -chdir="${fixture_dir}" init -backend=false -input=false -no-color >/dev/null

  set +e
  terraform -chdir="${fixture_dir}" plan -input=false -no-color -var-file="${tfvars_file}" >/dev/null 2>&1
  local rc=$?
  set -e

  if [[ "${expect_fail}" == "true" && "${rc}" -eq 0 ]]; then
    echo "Expected failure but plan succeeded for ${name}:${tfvars_file}"
    return 1
  fi

  if [[ "${expect_fail}" == "false" && "${rc}" -ne 0 ]]; then
    echo "Expected success but plan failed for ${name}:${tfvars_file}"
    return 1
  fi

  echo "PASS: ${name}:${tfvars_file}"
}

run_fixture "ssh_cidr" "good.tfvars" "false"
run_fixture "ssh_cidr" "bad.tfvars" "true"
run_fixture "environment_name" "good.tfvars" "false"
run_fixture "environment_name" "bad.tfvars" "true"

echo "All guardrail tests passed."

#!/bin/bash

set -euo pipefail

echo "$PWD"

echo "Starting Terraform code quality checks"

terragrunt run --all init

terragrunt run --all --filter-affected -- plan  -out=/tmp/tfplan

terragrunt run --all -- show -json /tmp/tfplan > /tmp/tfplan.json

while IFS= read -r plan; do
  if [ "$first" -eq 1 ]; then
    checkov -f "$plan" \
      --framework terraform_plan \
      --output sarif \
      --output-file-path /tmp \
      --output-file-name results_sarif.sarif \
      --repo-root-for-plan-enrichment .
    first=0
  else
    # write separate sarif files for each plan (simpler than trying to append)
    name="$(echo "$plan" | sed 's#[/ ]#_#g')"
    checkov -f "$plan" \
      --framework terraform_plan \
      --output sarif \
      --output-file-path /tmp \
      --output-file-name "results_${name}.sarif" \
      --repo-root-for-plan-enrichment .
  fi
done < <(find . -name tfplan.json -type f)
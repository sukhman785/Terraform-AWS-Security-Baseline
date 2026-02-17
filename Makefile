SHELL := /bin/bash

TF_DIR := terraform

.PHONY: help fmt fmt-check init validate lint tfsec checkov guardrails ci-local

help:
	@echo "Available targets:"
	@echo "  make fmt         - Format Terraform files"
	@echo "  make fmt-check   - Check Terraform formatting"
	@echo "  make init        - Terraform init (backend disabled)"
	@echo "  make validate    - Terraform validate"
	@echo "  make lint        - Run tflint"
	@echo "  make tfsec       - Run tfsec scan"
	@echo "  make checkov     - Run checkov scan"
	@echo "  make guardrails  - Run negative/positive guardrail tests"
	@echo "  make ci-local    - Run local CI-equivalent checks"

fmt:
	terraform fmt -recursive $(TF_DIR)

fmt-check:
	terraform fmt -check -recursive $(TF_DIR)

init:
	cd $(TF_DIR) && terraform init -backend=false

validate: init
	cd $(TF_DIR) && terraform validate

lint:
	tflint --init
	tflint --chdir=$(TF_DIR) --recursive

tfsec:
	tfsec $(TF_DIR)

checkov:
	checkov -d $(TF_DIR) --framework terraform --compact

guardrails:
	bash scripts/run-guardrail-tests.sh

ci-local: fmt-check validate lint guardrails

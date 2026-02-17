# Demo Runbook (10 Minutes)

## Goal

Show that this repository enforces preventative security guardrails, validates in CI, and provisions a runtime security baseline.

## Demo Flow

### 1) Show local guardrail tests (2 minutes)

```bash
make guardrails
```

What to say:
- "These tests verify we reject insecure inputs before deployment."
- "Example: SSH from `0.0.0.0/0` is blocked by Terraform validation."

### 2) Show local quality gates (2 minutes)

```bash
make fmt-check
make validate
```

What to say:
- "Formatting and validation are enforced locally and in CI."
- "The same checks run in GitHub Actions to block bad merges."

### 3) Show CI pipeline in GitHub Actions (2 minutes)

Open the `Terraform Security Validation` workflow and point out:
- `terraform-fmt`
- `terraform-validate`
- `terraform-lint`
- `guardrail-tests`
- `security-scan-tfsec`
- `security-scan-checkov`
- `terraform-plan`

What to say:
- "Security is shift-left: lint + security scans + plan review happen before merge."

### 4) Show a plan with environment config (2 minutes)

```bash
cp examples/dev.tfvars.example terraform/dev.tfvars
cd terraform
terraform init
terraform plan -var-file=dev.tfvars
```

What to say:
- "Fork users can start from an example file and get a working plan quickly."
- "Dev can use single NAT for cost optimization while keeping prod highly available."

### 5) Show runtime security outputs (2 minutes)

After apply, run:

```bash
terraform output cloudtrail_name
terraform output guardduty_detector_id
terraform output security_hub_enabled
```

What to say:
- "This is defense in depth: not only provisioning guardrails, but runtime detection services are enabled."

## Interview Talking Points

- "I enforced immutable security guardrails using Terraform validation and secure defaults."
- "I built a CI pipeline that fails on lint, policy misconfigurations, and insecure IaC patterns."
- "I separated concerns with modular Terraform and added environment-specific overlays for dev/staging/prod."
- "I added runtime controls (CloudTrail, GuardDuty, Security Hub) to move beyond static checks."

## Common Q&A

Q: "How can someone reuse this?"
A: "Fork the repo, copy a tfvars example, set AWS credentials, and run the documented commands."

Q: "How do you prove security guardrails work?"
A: "Guardrail tests include failing fixtures that intentionally attempt insecure values."

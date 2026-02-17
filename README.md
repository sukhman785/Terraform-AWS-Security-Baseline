# Secure AWS Foundation – Infrastructure Guardrails & DevSecOps Baseline

![Terraform Security Validation](https://github.com/sukhman785/Secure-AWS-Foundation-Infrastructure-Guardrails-DevSecOps-Baseline/actions/workflows/terraform-security.yml/badge.svg)

## Overview

Secure AWS Foundation is an opinionated Infrastructure-as-Code (IaC) template designed to provision a secure-by-default AWS environment using Terraform. It focuses on enforcing preventative security guardrails at provisioning time and integrating CI validation workflows.

## Problem Statement

Cloud environments are frequently misconfigured due to:
- Overly permissive IAM roles
- Open security groups
- Unencrypted storage
- Public S3 buckets
- Lack of CI validation

This project demonstrates how to enforce preventative guardrails before infrastructure is deployed.

## Architecture

```
┌─────────────────────────────────────────────┐
│           Secure AWS Foundation              │
├─────────────────────────────────────────────┤
│                                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │   VPC    │  │   IAM    │  │    S3    │  │
│  │ Module   │  │  Module  │  │  Module  │  │
│  └──────────┘  └──────────┘  └──────────┘  │
│                                             │
│  ┌──────────┐  ┌──────────────────────────┐│
│  │  EC2     │  │  Security Guardrails     ││
│  │ Module   │  │  - No 0.0.0.0/0 SSH      ││
│  └──────────┘  │  - S3 Public Block       ││
│                │  - IAM Least Privilege   ││
│                │  - Encryption Enforced   ││
│                └──────────────────────────┘│
└─────────────────────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────────────┐
│           CI/CD Pipeline                     │
│  - Terraform Validate                        │
│  - Security Scanning (tfsec/checkov)         │
│  - Plan Review                               │
└─────────────────────────────────────────────┘
```

## Quick Start

### Prerequisites

- Terraform >= 1.0
- AWS CLI configured
- AWS credentials with appropriate permissions
- Optional local tooling for full checks: `tflint`, `tfsec`, `checkov`

### Fork Setup (for GitHub users)

```bash
git clone https://github.com/<your-username>/Secure-AWS-Foundation-Infrastructure-Guardrails-DevSecOps-Baseline.git
cd Secure-AWS-Foundation-Infrastructure-Guardrails-DevSecOps-Baseline
cp examples/dev.tfvars.example terraform/dev.tfvars
```

Edit `terraform/dev.tfvars`:
- `project_name` (must be unique enough for S3 bucket naming)
- `allowed_ssh_cidr` (your trusted IP range, never `0.0.0.0/0`)

### Basic Usage

```bash
# Local CI-equivalent checks
make ci-local

# Initialize and plan
cd terraform
terraform init
terraform plan -var-file=dev.tfvars -out=tfplan

# Apply
terraform apply tfplan
```

### Runtime Security Outputs (after apply)

```bash
cd terraform
terraform output cloudtrail_name
terraform output guardduty_detector_id
terraform output security_hub_enabled
```

### Demo Runbook

See [DEMO.md](./DEMO.md) for a 10-minute interview-ready walkthrough.

### CI for Forks

This repository uses GitHub OIDC for AWS auth in CI plan jobs.  
Set `AWS_ROLE_TO_ASSUME` in your fork's repository secrets before enabling plan jobs.

Minimum CI path that works without AWS credentials:
- format
- validate
- lint
- guardrail tests
- tfsec/checkov

Plan job requires AWS credentials via OIDC role assumption.

## Project Structure

```
.
├── terraform/
│   ├── main.tf              # Root module
│   ├── variables.tf         # Input variables
│   ├── outputs.tf           # Output values
│   ├── versions.tf          # Provider versions
│   └── modules/
│       ├── networking/      # VPC, subnets, security groups
│       ├── compute/         # EC2 instances
│       ├── storage/         # S3 buckets
│       ├── iam/             # IAM roles and policies
│       ├── security/        # KMS and encryption baseline
│       └── monitoring_security/ # CloudTrail, GuardDuty, Security Hub
├── .github/workflows/       # CI/CD pipelines
├── tests/                   # Guardrail and verification tests
├── DEMO.md                  # 10-minute demo script
└── examples/                # Usage examples
```

## Security Guardrails

### Enforced at Provisioning Time

- ✅ **No Open SSH**: Security groups restrict SSH to specific CIDR blocks only
- ✅ **S3 Public Access Block**: All S3 buckets have public access blocked by default
- ✅ **No Wildcard IAM**: IAM policies use specific resource ARNs
- ✅ **Encryption Enforced**: S3 buckets use AES-256 or KMS encryption
- ✅ **CI Validation**: Pipeline fails on insecure configurations

## Success Metrics

- ✅ Terraform apply completes successfully
- ✅ Security scanner reports zero critical issues
- ✅ CI blocks insecure infrastructure changes
- ✅ Clear documentation of architectural decisions

## Non-Goals

This project does **not** aim to:
- Replace enterprise landing zone frameworks (AWS Control Tower, etc.)
- Implement multi-account AWS Organizations setup
- Build a SaaS control plane
- Provide continuous runtime monitoring

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines.

## License

MIT License - See [LICENSE](./LICENSE) for details.

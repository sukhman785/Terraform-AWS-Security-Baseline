# Contributing Guide

## Branching

- Create a feature branch from `main`.
- Keep pull requests scoped to one milestone or one logical change set.

## Terraform Workflow

1. Update Terraform code and docs together when behavior changes.
2. Run local checks before opening a PR:
   - `make ci-local`
3. If available in your environment, run security scans:
   - `make tfsec`
   - `make checkov`

## Security Expectations

- Do not weaken existing guardrails (SSH restrictions, S3 public access block, encryption defaults).
- Use least privilege IAM; avoid wildcard permissions unless tightly constrained and documented.
- Never commit secrets or credentials.

## Pull Request Checklist

- Terraform is formatted.
- Validation passes locally.
- Guardrail tests pass.
- New variables are documented in examples.
- Docs updated for user-facing behavior changes.
- CI passes.

## Commit Guidance

- Use clear, scoped commit messages.
- Prefer small commits that are easy to review and revert.

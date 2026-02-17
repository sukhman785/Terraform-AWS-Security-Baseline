terraform {
  required_version = ">= 1.0"
}

variable "environment" {
  description = "Environment name guardrail test fixture"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

output "environment" {
  value = var.environment
}

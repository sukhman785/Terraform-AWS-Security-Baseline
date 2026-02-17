terraform {
  required_version = ">= 1.0"
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH (guardrail test fixture)"
  type        = string

  validation {
    condition     = var.allowed_ssh_cidr != "0.0.0.0/0"
    error_message = "SSH access from 0.0.0.0/0 is not allowed."
  }
}

output "allowed_ssh_cidr" {
  value = var.allowed_ssh_cidr
}

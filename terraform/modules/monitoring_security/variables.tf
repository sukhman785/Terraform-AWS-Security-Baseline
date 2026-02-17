variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "kms_key_arn" {
  description = "KMS key ARN used for CloudTrail log encryption"
  type        = string
}

variable "enable_runtime_security" {
  description = "Enable runtime security resources in this module"
  type        = bool
  default     = true
}

variable "enable_cloudtrail" {
  description = "Enable CloudTrail logging resources"
  type        = bool
  default     = true
}

variable "enable_guardduty" {
  description = "Enable GuardDuty detector"
  type        = bool
  default     = false
}

variable "enable_security_hub" {
  description = "Enable Security Hub account"
  type        = bool
  default     = false
}

variable "cloudtrail_log_retention_days" {
  description = "CloudWatch log retention period for CloudTrail logs"
  type        = number
  default     = 90
}

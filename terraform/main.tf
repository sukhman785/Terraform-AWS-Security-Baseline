# Main Terraform configuration for Secure AWS Foundation

# Data source to get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# Networking Module - VPC, Subnets, Security Groups
module "networking" {
  source = "./modules/networking"

  project_name            = var.project_name
  environment             = var.environment
  vpc_cidr                = var.vpc_cidr
  availability_zones      = slice(data.aws_availability_zones.available.names, 0, var.az_count)
  public_subnet_cidrs     = var.public_subnet_cidrs
  private_subnet_cidrs    = var.private_subnet_cidrs
  allowed_ssh_cidr        = var.allowed_ssh_cidr
  single_nat_gateway      = var.single_nat_gateway
  enable_nat_gateway      = var.enable_nat_gateway
  kms_key_arn             = module.security.kms_key_arn
  flow_log_retention_days = var.vpc_flow_log_retention_days
}

# IAM Module - Roles and Policies
module "iam" {
  source = "./modules/iam"

  project_name = var.project_name
  environment  = var.environment
}

# Storage Module - S3 Buckets with Security Controls
module "storage" {
  source = "./modules/storage"

  project_name = var.project_name
  environment  = var.environment
  kms_key_arn  = module.security.kms_key_arn
}

# Security Module - KMS Keys and Security Baseline
module "security" {
  source = "./modules/security"

  project_name = var.project_name
  environment  = var.environment
}

# Monitoring & Runtime Security Module
module "monitoring_security" {
  source = "./modules/monitoring_security"

  project_name                  = var.project_name
  environment                   = var.environment
  enable_runtime_security       = var.enable_runtime_security
  kms_key_arn                   = module.security.kms_key_arn
  enable_cloudtrail             = var.enable_cloudtrail
  enable_guardduty              = var.enable_guardduty
  enable_security_hub           = var.enable_security_hub
  cloudtrail_log_retention_days = var.cloudtrail_log_retention_days
}

# Compute Module - EC2 Instances (Optional)
module "compute" {
  source = "./modules/compute"
  count  = var.create_bastion ? 1 : 0

  project_name          = var.project_name
  environment           = var.environment
  public_subnet_ids     = module.networking.public_subnet_ids
  security_group_ids    = [module.networking.bastion_security_group_id]
  instance_profile_name = module.iam.instance_profile_name
  instance_type         = var.bastion_instance_type
}

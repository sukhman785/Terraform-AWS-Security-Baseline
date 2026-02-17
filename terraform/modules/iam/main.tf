terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# IAM Role for EC2 Instances
resource "aws_iam_role" "instance_role" {
  name = "${var.project_name}-${var.environment}-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-${var.environment}-instance-role"
  }
}

# SECURITY GUARDRAIL: Least-privilege policy with specific resource ARNs
# This is an example policy - customize based on your needs
resource "aws_iam_role_policy" "instance_policy" {
  name = "${var.project_name}-${var.environment}-instance-policy"
  role = aws_iam_role.instance_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Effect = "Allow"
        # SECURITY: Specific resource ARN instead of "*"
        # Replace with actual bucket ARN in production
        Resource = "arn:aws:s3:::${var.project_name}-${var.environment}-*/*"
      },
      {
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Effect = "Allow"
        # SECURITY: Namespace-specific permission
        Resource = "*"
        Condition = {
          StringEquals = {
            "cloudwatch:namespace" = "${var.project_name}/${var.environment}"
          }
        }
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect = "Allow"
        # SECURITY: Specific log group prefix
        Resource = "arn:aws:logs:*:*:log-group:/aws/${var.project_name}/${var.environment}/*"
      }
    ]
  })
}

# Attach AWS managed policy for SSM Session Manager (secure alternative to SSH)
resource "aws_iam_role_policy_attachment" "ssm_managed_instance" {
  role       = aws_iam_role.instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance Profile
resource "aws_iam_instance_profile" "instance_profile" {
  name = "${var.project_name}-${var.environment}-instance-profile"
  role = aws_iam_role.instance_role.name

  tags = {
    Name = "${var.project_name}-${var.environment}-instance-profile"
  }
}

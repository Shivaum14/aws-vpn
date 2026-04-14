# variables.tf — Input variable declarations for the dev environment.
#
# Variables are the equivalent of CloudFormation Parameters. Unlike CloudFormation,
# Terraform variables are declared here but their values come from one of:
#   1. terraform.tfvars (gitignored — your real values go here)
#   2. -var flags on the CLI
#   3. TF_VAR_* environment variables
#   4. The default value defined below (used if nothing else is provided)
#
# Variables with no default are required — Terraform will error if they are
# not provided. Variables used as resource tags (region, project, environment)
# are safe to default here since they are not sensitive and have clear meanings.

# ---------------------------------------------------------------------------
# AWS provider
# ---------------------------------------------------------------------------

variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "eu-west-2"
}

variable "aws_profile" {
  description = "AWS CLI named profile to use for authentication. Must resolve to aws_account_id."
  type        = string
  default     = "dev"
}

variable "aws_account_id" {
  description = "Expected AWS account ID. Terraform will refuse to run if credentials resolve to any other account."
  type        = string
  # No default — must be set explicitly in terraform.tfvars to prevent
  # accidental deployment into the wrong account.
}

# ---------------------------------------------------------------------------
# Naming and tagging
# ---------------------------------------------------------------------------

variable "project" {
  description = "Project name. Applied as a tag to all resources."
  type        = string
  default     = "aws-vpn"
}

variable "environment" {
  description = "Deployment environment name (e.g. dev, staging). Applied as a tag to all resources."
  type        = string
  default     = "dev"
}

# ---------------------------------------------------------------------------
# Networking (required — no defaults, must be set in terraform.tfvars)
# ---------------------------------------------------------------------------

variable "vpc_id" {
  description = "ID of the existing VPC to deploy into."
  type        = string
}

variable "subnet_id" {
  description = "ID of a public subnet within the VPC. Must have a route to an internet gateway."
  type        = string
}

# ---------------------------------------------------------------------------
# Instance access (required — no defaults, must be set in terraform.tfvars)
# ---------------------------------------------------------------------------

variable "key_name" {
  description = "Name of an existing EC2 key pair for SSH access. Create with: aws ec2 create-key-pair --key-name aws-vpn-dev --profile dev"
  type        = string
}

variable "operator_cidr" {
  description = "Your public IP in CIDR notation (e.g. \"203.0.113.5/32\"). Only this address can SSH to the instance. Run: curl -s https://checkip.amazonaws.com"
  type        = string
}

# ---------------------------------------------------------------------------
# WireGuard (optional — defaults to open for roaming clients)
# ---------------------------------------------------------------------------

variable "wireguard_allowed_cidrs" {
  description = "CIDR blocks permitted to reach UDP 51820. Defaults to open for roaming clients. Narrow if your egress IP is fixed."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

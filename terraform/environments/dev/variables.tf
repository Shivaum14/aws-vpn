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

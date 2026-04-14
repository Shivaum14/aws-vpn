# variables.tf — Input variable declarations for the vpn-instance module.
#
# Variables defined here are the module's public interface — the root module
# must pass values for any variable that has no default.
#
# Convention: required inputs (no default) are listed first so the contract
# is immediately visible. Optional inputs with defaults follow.

# ---------------------------------------------------------------------------
# Required inputs (no default — must be supplied by the root module)
# ---------------------------------------------------------------------------

variable "vpc_id" {
  description = "ID of the VPC to deploy the VPN instance into."
  type        = string
}

variable "subnet_id" {
  description = "ID of the public subnet to place the instance in. Must have a route to an internet gateway."
  type        = string
}

variable "key_name" {
  description = "Name of the EC2 key pair to use for SSH access. The key pair must already exist in the target region."
  type        = string
}

variable "operator_cidr" {
  description = "CIDR block permitted to SSH to the instance. Set to your public IP: \"YOUR_IP/32\". Never 0.0.0.0/0."
  type        = string
}

variable "aws_account_id" {
  description = "AWS account ID. Used to scope the SSM Parameter Store IAM policy to this account."
  type        = string
}

variable "aws_region" {
  description = "AWS region. Used to construct the SSM Parameter Store ARN."
  type        = string
}

# ---------------------------------------------------------------------------
# Optional inputs (have defaults)
# ---------------------------------------------------------------------------

variable "project" {
  description = "Project name. Used in resource names and tags."
  type        = string
  default     = "aws-vpn"
}

variable "environment" {
  description = "Deployment environment name. Used in resource names and tags."
  type        = string
  default     = "dev"
}

variable "wireguard_allowed_cidrs" {
  description = <<-EOT
    List of CIDR blocks permitted to reach the WireGuard port (UDP 51820).
    Defaults to open (0.0.0.0/0) because VPN clients are typically roaming
    (dynamic home IPs, mobile devices). Narrow this if your egress IP is
    fixed — it reduces exposure but is not required for correctness.
  EOT
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

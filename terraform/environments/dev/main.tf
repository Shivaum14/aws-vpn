# main.tf — Provider configuration and module wiring for the dev environment.
#
# In Terraform, the "root module" is the directory you run `terraform apply`
# from. This file does two things:
#   1. Configures the AWS provider (region, default tags)
#   2. Calls the vpn-instance child module, passing in environment-specific values
#
# Child modules (under terraform/modules/) define reusable resource groups.
# The root module is responsible for instantiating them with the right inputs.

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  # allowed_account_ids is a hard safety guardrail. Terraform will refuse to
  # run if the resolved credentials belong to any account not in this list.
  # This prevents accidental applies against prod even if the wrong profile
  # is set in the environment — the check happens before any AWS API calls.
  allowed_account_ids = [var.aws_account_id]

  # default_tags applies these tags to every resource managed by this provider
  # block. Any resource-level tags are merged on top. This avoids repeating
  # the same three tags on every resource definition throughout the config.
  # The ManagedBy tag is a convention that signals to anyone in the AWS console
  # that this resource is owned by Terraform — don't edit it by hand.
  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

module "vpn" {
  source = "../../modules/vpn-instance"

  # Variables are passed to the module here as the module gains inputs (PR 3+).
}

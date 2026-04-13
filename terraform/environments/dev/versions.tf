# versions.tf — Terraform and provider version constraints.
#
# This file declares:
#   - the minimum Terraform CLI version this config requires
#   - the external providers (think: SDKs) Terraform needs to download
#
# Pinning versions here ensures everyone on the team (and CI) uses compatible
# tooling. The companion .terraform.lock.hcl records exact checksums after
# `terraform init`, similar to package-lock.json in Node.

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    # hashicorp/aws is the official AWS provider — it knows how to create and
    # manage every AWS resource type. ~> 5.0 means "any 5.x version", which
    # allows patch updates but prevents a major-version bump from silently
    # breaking the config.
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

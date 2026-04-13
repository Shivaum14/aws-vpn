# outputs.tf — Values exposed after terraform apply.
#
# Outputs are the equivalent of CloudFormation Outputs. They let you inspect
# key values after a deployment (e.g. the Elastic IP address, instance ID)
# without digging through the AWS console, and they can be read by other
# tools (e.g. the gen-inventory.sh script reads the EIP from here).
#
# This file is empty until the vpn-instance module produces real resources
# to expose (PR 3). Outputs are added here as the module gains outputs.

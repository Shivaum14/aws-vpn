# outputs.tf — Values exposed after terraform apply.
#
# Outputs are the equivalent of CloudFormation Outputs. They let you inspect
# key values after a deployment (e.g. the Elastic IP address, instance ID)
# without digging through the AWS console, and they can be read by other
# tools (e.g. the gen-inventory.sh script reads the EIP from here).

output "eip_address" {
  description = "Elastic IP address of the VPN server. VPN clients connect to this address."
  value       = module.vpn.eip_address
}

output "instance_id" {
  description = "EC2 instance ID. Use to connect via SSM or to stop/start the instance."
  value       = module.vpn.instance_id
}

output "private_ip" {
  description = "Private IP of the VPN instance within the VPC."
  value       = module.vpn.private_ip
}

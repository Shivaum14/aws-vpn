# outputs.tf — Values the vpn-instance module exposes to its caller.
#
# Module outputs work like return values — the root module references them
# as module.vpn.<output_name> and can re-expose them in its own outputs.tf.

output "eip_address" {
  description = "The Elastic IP address assigned to the VPN instance. VPN clients connect to this address."
  value       = aws_eip.vpn.public_ip
}

output "instance_id" {
  description = "EC2 instance ID. Use this to connect via SSM or to stop/start the instance."
  value       = aws_instance.vpn.id
}

output "private_ip" {
  description = "Private IP of the instance within the VPC. Useful for verifying VPC-internal routing."
  value       = aws_instance.vpn.private_ip
}

# outputs.tf — Values the vpn-instance module exposes to its caller.
#
# Module outputs work like return values — the root module can reference them
# as module.vpn.<output_name> and re-expose them in its own outputs.tf.
#
# Outputs are added here in PR 3: eip_address, instance_id, private_ip.

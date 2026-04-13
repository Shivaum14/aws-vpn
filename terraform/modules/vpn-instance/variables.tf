# variables.tf — Input variable declarations for the vpn-instance module.
#
# Variables defined here are the module's public interface — the root module
# must pass values for any variable that has no default.
#
# Variables are added here in PR 3 alongside the resources that consume them
# (vpc_id, subnet_id, key_name, operator_cidr, etc.).

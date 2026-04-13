# main.tf — Resource definitions for the vpn-instance module.
#
# This is a child module called from terraform/environments/dev/main.tf.
# Child modules define reusable groups of resources. The calling root module
# passes in variable values to customise the deployment per environment.
#
# Child modules do not declare a provider or backend — those are inherited
# from the root module that instantiates them.
#
# This module is currently an empty scaffold. Resources are introduced once
# the module skeleton is in place.

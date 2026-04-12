# aws-vpn

A self-hosted WireGuard VPN server on AWS. Terraform provisions the infrastructure, Ansible
configures the host, and a Python CLI manages client provisioning — all with clean separation of
concerns, no secrets in git, and a repeatable destroy/recreate lifecycle.

## Architecture

```
Your laptop / phone
        │
     UDP 51820
        │
[Elastic IP] ──► [EC2 / WireGuard server]
                        │  wg0: 10.8.0.1/24
                        │
               iptables MASQUERADE
                        │
              [VPC private resources]
                  e.g. 10.0.x.x
```

A single EC2 instance runs WireGuard in a public subnet with a stable Elastic IP. VPN clients are
NAT-masqueraded so they can reach VPC-private resources without any VPC route table changes.

## Stack

| Tool | Role |
|---|---|
| [WireGuard](https://www.wireguard.com/) | VPN protocol |
| [Terraform](https://www.terraform.io/) | AWS infrastructure (EC2, SG, IAM, EIP) |
| [Ansible](https://www.ansible.com/) | Host configuration and WireGuard setup |
| [Python](https://www.python.org/) | Client lifecycle CLI |
| [GitHub Actions](https://github.com/features/actions) | CI: lint, validate, terraform plan |

## Repository structure

```
terraform/          # AWS infrastructure
ansible/            # Host configuration
tools/              # Python client-management CLI
scripts/            # Helper scripts
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for the development workflow and conventions.

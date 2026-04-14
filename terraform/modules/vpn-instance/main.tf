# main.tf — Resource definitions for the vpn-instance module.
#
# This is a child module called from terraform/environments/dev/main.tf.
# Child modules define reusable groups of resources. The calling root module
# passes in variable values to customise the deployment per environment.
#
# Child modules do not declare a provider or backend — those are inherited
# from the root module that instantiates them.
#
# Resources defined here (in order):
#   1. Data sources     — look up AMI and VPC/subnet details from AWS
#   2. Security group   — controls inbound/outbound traffic to the instance
#   3. IAM role         — grants the instance permission to use SSM and Parameter Store
#   4. EC2 instance     — the WireGuard server itself
#   5. Elastic IP       — stable public IP address for VPN clients to connect to
#   6. EIP association  — attaches the Elastic IP to the instance

# ---------------------------------------------------------------------------
# Data sources
# ---------------------------------------------------------------------------

# Look up the most recent Amazon Linux 2023 AMI.
#
# Why Amazon Linux 2023?
#   - WireGuard is built into the AL2023 kernel (no DKMS module needed)
#   - SSM agent is pre-installed
#   - Maintained by AWS with timely security patches
#   - Familiar to anyone using AWS
#
# Why filter by name pattern rather than hardcoding an AMI ID?
#   AMI IDs are region-specific and change with every new release. A data
#   source lookup always resolves the latest version in the target region,
#   so the config stays correct without manual updates.
#
# most_recent = true ensures we get the newest image if multiple match.
# The owners filter limits results to Amazon's official account (137112412989)
# so we never accidentally pick up a community or marketplace AMI.
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Look up the VPC by ID so we can reference its CIDR block in comments and
# potentially in future security group rules. Terraform validates that the
# VPC exists in the target account when this data source is evaluated.
data "aws_vpc" "main" {
  id = var.vpc_id
}

# Look up the subnet so Terraform validates it exists before the instance
# resource is planned. The instance resource references this directly.
data "aws_subnet" "public" {
  id = var.subnet_id
}

# ---------------------------------------------------------------------------
# Security group
# ---------------------------------------------------------------------------

# The security group is the network firewall for the instance.
#
# Inbound rules:
#   - UDP 51820: WireGuard traffic. Defaults to open (0.0.0.0/0 + ::/0) because
#     VPN clients are typically roaming (dynamic home IPs, mobile devices). If
#     your egress IP is fixed you can narrow this via var.wireguard_allowed_cidrs.
#   - TCP 22: SSH access, restricted to var.operator_cidr only. This is a required
#     input — there is no default. You must explicitly set your IP.
#
# Outbound rules:
#   - All traffic allowed. The instance needs to forward packets on behalf of
#     VPN clients (NAT masquerade), so it must be able to reach any destination.
#
# Security group rules are stateful — a rule permitting inbound traffic
# automatically permits the return traffic. You do not need explicit outbound
# rules for responses to allowed inbound connections.
resource "aws_security_group" "vpn" {
  name        = "${var.project}-${var.environment}-vpn"
  description = "WireGuard VPN server — WireGuard ingress and restricted SSH"
  vpc_id      = data.aws_vpc.main.id

  # WireGuard — UDP 51820
  # Defaults to open for roaming clients (mobile, dynamic home IPs).
  # Set var.wireguard_allowed_cidrs to narrow if you have a fixed egress IP.
  ingress {
    description = "WireGuard VPN"
    from_port   = 51820
    to_port     = 51820
    protocol    = "udp"
    cidr_blocks = var.wireguard_allowed_cidrs
  }

  # SSH — TCP 22, restricted to operator IP only
  # var.operator_cidr has no default — you must supply your IP explicitly.
  # Typically "YOUR_PUBLIC_IP/32". Never open to 0.0.0.0/0.
  ingress {
    description = "SSH from operator CIDR"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.operator_cidr]
  }

  # All outbound allowed — required for NAT forwarding and package installs
  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}-${var.environment}-vpn"
  }
}

# ---------------------------------------------------------------------------
# IAM role and instance profile
# ---------------------------------------------------------------------------

# IAM roles for EC2 follow a two-step pattern:
#
#   1. aws_iam_role: declares the role and its trust policy — who can assume it.
#      The trust policy here allows EC2 (ec2.amazonaws.com) to assume the role,
#      which is how instance profiles work. No other principal can assume it.
#
#   2. aws_iam_instance_profile: wraps the role so EC2 can attach it to an
#      instance. An instance profile is just a container for a single IAM role.
#      (This is an AWS API distinction — the console hides it.)
#
#   3. aws_iam_role_policy_attachment (×2): attaches AWS-managed policies to
#      the role. Attaching policies to a role (not a user or group) and using
#      an instance profile is the correct pattern — never use static access keys
#      on an EC2 instance.
#
# Permissions granted:
#   - AmazonSSMManagedInstanceCore: allows SSM Session Manager to connect to
#     the instance without opening port 22 to the internet. Useful for ad-hoc
#     debugging. Session Manager requires the SSM agent (pre-installed on AL2023),
#     an instance profile with this policy, and network access to SSM endpoints.
#   - ssm:GetParameter / ssm:PutParameter on /vpn/*: allows Ansible to store
#     the WireGuard server public key in SSM Parameter Store, and the Python
#     CLI to retrieve it when generating client configs. Scoped to /vpn/* only
#     (least-privilege — the instance cannot read unrelated parameters).

data "aws_iam_policy_document" "ec2_assume_role" {
  # This is the trust policy — it controls who can assume the role.
  # "Effect: Allow" + "Principal: ec2.amazonaws.com" + "Action: sts:AssumeRole"
  # is the standard boilerplate for an EC2 instance role.
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "vpn" {
  name               = "${var.project}-${var.environment}-vpn"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = {
    Name = "${var.project}-${var.environment}-vpn"
  }
}

# SSM Session Manager — lets you connect to the instance via the AWS console
# or CLI without needing SSH. Also required for SSM Run Command used by Ansible.
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.vpn.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Inline policy: allows the instance to read/write SSM parameters under /vpn/
# Scoped to the exact path prefix — no broader access to Parameter Store.
resource "aws_iam_role_policy" "ssm_parameters" {
  name = "ssm-vpn-parameters"
  role = aws_iam_role.vpn.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameter",
          "ssm:PutParameter",
        ]
        Resource = "arn:aws:ssm:${var.aws_region}:${var.aws_account_id}:parameter/vpn/*"
      }
    ]
  })
}

# The instance profile is the container that attaches the IAM role to an EC2
# instance. There is always a 1:1 relationship between a role and its instance
# profile in this pattern.
resource "aws_iam_instance_profile" "vpn" {
  name = "${var.project}-${var.environment}-vpn"
  role = aws_iam_role.vpn.name

  tags = {
    Name = "${var.project}-${var.environment}-vpn"
  }
}

# ---------------------------------------------------------------------------
# EC2 instance
# ---------------------------------------------------------------------------

# The WireGuard server instance.
#
# Key decisions:
#
#   instance_type = t3.micro
#     Adequate for a personal VPN server. WireGuard is lightweight — the kernel
#     module does encryption in-kernel with minimal CPU overhead.
#
#   source_dest_check = false
#     By default, AWS validates that a packet's source IP matches the sending
#     ENI's IP, and that the destination IP matches the ENI's IP. This check
#     must be disabled on the WireGuard instance because it forwards and
#     NAT-rewrites traffic on behalf of other IPs. Without disabling this,
#     AWS will silently drop forwarded packets.
#
#   associate_public_ip_address = false
#     We attach a separate Elastic IP instead of a dynamic public IP. This
#     gives a stable address that survives stop/start cycles and is detachable.
#     The auto-assigned public IP would change on every stop/start.
#
#   key_name
#     The EC2 key pair to use for SSH access. The key pair must already exist
#     in the target region — it is not created by Terraform. This is intentional:
#     creating a key pair in Terraform stores the private key in Terraform state,
#     which would make it visible to anyone with state access. Managing it
#     externally and passing only the name here avoids that risk.

resource "aws_instance" "vpn" {
  ami                         = data.aws_ami.al2023.id
  instance_type               = "t3.micro"
  subnet_id                   = data.aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.vpn.id]
  iam_instance_profile        = aws_iam_instance_profile.vpn.name
  key_name                    = var.key_name
  source_dest_check           = false
  associate_public_ip_address = false

  # Minimal user data: ensure SSM agent is running.
  # AL2023 ships with the SSM agent pre-installed, but we explicitly start it
  # in case the service is not active after a first boot.
  user_data = <<-EOT
    #!/bin/bash
    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent
  EOT

  tags = {
    Name = "${var.project}-${var.environment}-vpn-server"
  }

  # Ensure the IAM profile is fully created before launching the instance.
  # Without this, the instance may launch before the profile is ready and
  # the SSM agent won't be able to register.
  depends_on = [aws_iam_instance_profile.vpn]
}

# ---------------------------------------------------------------------------
# Elastic IP and association
# ---------------------------------------------------------------------------

# An Elastic IP is a static public IPv4 address. Unlike the auto-assigned
# public IP (which changes on stop/start), an EIP persists across instance
# lifecycle events. VPN clients always connect to this address.
#
# domain = "vpc" is required for EIPs used with VPC instances (vs the older
# EC2-Classic network mode which is no longer available on new accounts).
resource "aws_eip" "vpn" {
  domain = "vpc"

  tags = {
    Name = "${var.project}-${var.environment}-vpn"
  }
}

# Associates the EIP with the instance.
# The EIP and instance are created as separate resources and linked here.
# This allows the EIP to be re-associated with a new instance on redeploy
# without changing the public IP address (if the EIP resource itself is not
# destroyed). In this project's default lifecycle, the EIP is destroyed with
# the instance — but the separation makes it straightforward to preserve it
# if needed.
resource "aws_eip_association" "vpn" {
  instance_id   = aws_instance.vpn.id
  allocation_id = aws_eip.vpn.id
}

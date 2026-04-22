resource "aws_security_group" "instance" {
  name        = "${var.name_prefix}-instance-sg"
  description = "Security group for OpenClaw instance"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from trusted CIDRs"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_ingress_cidrs
  }

  dynamic "egress" {
    for_each = var.instance_egress_policies

    content {
      description = egress.value.description
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-instance-sg"
  })
}

resource "aws_network_acl" "default_allow" {
  count      = var.create_default_nacl ? 1 : 0
  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-default-nacl"
  })
}

locals {
  selected_key_name = var.key_name != "" ? var.key_name : try(aws_key_pair.generated[0].key_name, null)
}

data "aws_ami" "ubuntu" {
  count       = var.ami_id == "" ? 1 : 0
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "instance" {
  count = var.instance_profile_name == "" ? 1 : 0

  name               = "${var.name_prefix}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  count = var.instance_profile_name == "" ? 1 : 0

  role       = aws_iam_role.instance[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "instance" {
  count = var.instance_profile_name == "" ? 1 : 0

  name = "${var.name_prefix}-instance-profile"
  role = aws_iam_role.instance[0].name
}

resource "aws_key_pair" "generated" {
  count = var.key_name == "" && var.public_key_path != "" ? 1 : 0

  key_name   = "${var.name_prefix}-key"
  public_key = file(var.public_key_path)
}

resource "aws_instance" "this" {
  ami                         = var.ami_id != "" ? var.ami_id : data.aws_ami.ubuntu[0].id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.security_group_ids
  key_name                    = local.selected_key_name
  iam_instance_profile        = var.instance_profile_name != "" ? var.instance_profile_name : aws_iam_instance_profile.instance[0].name
  associate_public_ip_address = true

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
    encrypted   = true
  }

  metadata_options {
    http_tokens = "required"
  }

  user_data = <<-EOT
    #!/usr/bin/env bash
    set -euxo pipefail

    apt-get update -y
    apt-get install -y python3 python3-apt curl git

    ${var.additional_user_data}
  EOT

  tags = merge(var.common_tags, {
    Name = "${var.name_prefix}-host"
  })
}

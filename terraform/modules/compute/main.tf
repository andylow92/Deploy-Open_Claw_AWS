locals {
  selected_key_name            = var.key_name != "" ? var.key_name : try(aws_key_pair.generated[0].key_name, null)
  use_generated_profile        = var.instance_profile_name == "" && (var.enable_ssm || var.enable_cloudwatch_agent)
  resolved_instance_profile    = var.instance_profile_name != "" ? var.instance_profile_name : try(aws_iam_instance_profile.instance[0].name, null)
  should_attach_ssh_key        = !var.ssm_preferred_access
  cloudwatch_config_json = jsonencode({
    agent = {
      metrics_collection_interval = 60
      logfile                     = "/opt/aws/amazon-cloudwatch-agent/logs/amazon-cloudwatch-agent.log"
      run_as_user                 = "root"
    }
    metrics = {
      append_dimensions = {
        InstanceId = "$${aws:InstanceId}"
      }
      metrics_collected = {
        cpu = {
          measurement = ["cpu_usage_idle", "cpu_usage_iowait"]
          resources   = ["*"]
          totalcpu    = true
        }
        mem = {
          measurement = ["mem_used_percent"]
        }
        disk = {
          measurement = ["used_percent"]
          resources   = ["/"]
        }
      }
    }
    logs = {
      logs_collected = {
        files = {
          collect_list = [
            {
              file_path       = "/var/log/syslog"
              log_group_name  = "/ec2/${var.name_prefix}/syslog"
              log_stream_name = "{instance_id}"
              timezone        = "UTC"
            },
            {
              file_path       = "/var/log/auth.log"
              log_group_name  = "/ec2/${var.name_prefix}/auth"
              log_stream_name = "{instance_id}"
              timezone        = "UTC"
            },
            {
              file_path       = "/var/log/ollama/ollama.log"
              log_group_name  = "/ec2/${var.name_prefix}/ollama"
              log_stream_name = "{instance_id}"
              timezone        = "UTC"
            },
            {
              file_path       = "/var/log/openclaw/openclaw.log"
              log_group_name  = "/ec2/${var.name_prefix}/openclaw"
              log_stream_name = "{instance_id}"
              timezone        = "UTC"
            }
          ]
        }
      }
    }
  })

  managed_log_group_names = var.enable_cloudwatch_agent ? [
    "/ec2/${var.name_prefix}/syslog",
    "/ec2/${var.name_prefix}/auth",
    "/ec2/${var.name_prefix}/ollama",
    "/ec2/${var.name_prefix}/openclaw",
  ] : []
}

resource "aws_cloudwatch_log_group" "this" {
  for_each = toset(local.managed_log_group_names)

  name              = each.key
  retention_in_days = var.log_retention_days
  tags              = var.tags
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
  count = local.use_generated_profile ? 1 : 0

  name               = "${var.name_prefix}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  count = local.use_generated_profile && var.enable_ssm ? 1 : 0

  role       = aws_iam_role.instance[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  count = local.use_generated_profile && var.enable_cloudwatch_agent ? 1 : 0

  role       = aws_iam_role.instance[0].name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_instance_profile" "instance" {
  count = local.use_generated_profile ? 1 : 0

  name = "${var.name_prefix}-instance-profile"
  role = aws_iam_role.instance[0].name
}

resource "aws_key_pair" "generated" {
  count = local.should_attach_ssh_key && var.key_name == "" && var.public_key_path != "" ? 1 : 0

  key_name   = "${var.name_prefix}-key"
  public_key = file(var.public_key_path)
}

resource "aws_instance" "this" {
  ami                         = var.ami_id != "" ? var.ami_id : data.aws_ami.ubuntu[0].id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.security_group_ids
  key_name                    = local.should_attach_ssh_key ? local.selected_key_name : null
  iam_instance_profile        = local.resolved_instance_profile
  associate_public_ip_address = true

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true
  }

  user_data = <<-EOT
    #!/usr/bin/env bash
    set -euxo pipefail

    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get install -y python3 python3-apt curl git

    if [ "${var.enable_ssm}" = "true" ]; then
      snap install amazon-ssm-agent --classic || true
      systemctl enable --now snap.amazon-ssm-agent.amazon-ssm-agent.service || true
    fi

    if [ "${var.enable_cloudwatch_agent}" = "true" ]; then
      # Pinned CloudWatch agent version from Amazon's official S3 bucket (versioned path is immutable).
      CW_AGENT_VERSION="${var.cloudwatch_agent_version}"
      wget -q "https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/$${CW_AGENT_VERSION}/amazon-cloudwatch-agent.deb" -O /tmp/amazon-cloudwatch-agent.deb
      dpkg -i /tmp/amazon-cloudwatch-agent.deb
      install -d -m 0755 /var/log/ollama /var/log/openclaw
      cat > /opt/aws/amazon-cloudwatch-agent/bin/config.json <<'CWCFG'
${local.cloudwatch_config_json}
CWCFG
      /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/bin/config.json -s
    fi

    ${var.additional_user_data}
  EOT

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-host"
  })
}

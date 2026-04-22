# Core
variable "project_name" {
  description = "Project identifier"
  type        = string
  default     = "openclaw"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "owner" {
  description = "Owner (team or individual) responsible for the resources; propagated as an Owner tag."
  type        = string
  default     = "platform"
}

variable "tags" {
  description = "Common tags applied to resources"
  type        = map(string)
  default     = {}
}

# Network
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.42.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vpc_cidr))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block."
  }
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.42.1.0/24"]

  validation {
    condition     = length(var.public_subnet_cidrs) > 0
    error_message = "At least one public subnet CIDR is required."
  }

  validation {
    condition     = alltrue([for cidr in var.public_subnet_cidrs : can(cidrnetmask(cidr))])
    error_message = "All public_subnet_cidrs values must be valid IPv4 CIDRs."
  }
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.42.11.0/24"]

  validation {
    condition     = alltrue([for cidr in var.private_subnet_cidrs : can(cidrnetmask(cidr))])
    error_message = "All private_subnet_cidrs values must be valid IPv4 CIDRs."
  }
}

variable "availability_zones" {
  description = "Availability zones used by subnets"
  type        = list(string)
  default     = ["us-east-1a"]

  validation {
    condition     = length(var.availability_zones) > 0
    error_message = "availability_zones must contain at least one AZ."
  }

  validation {
    condition = (
      length(var.public_subnet_cidrs) <= length(var.availability_zones) &&
      length(var.private_subnet_cidrs) <= length(var.availability_zones)
    )
    error_message = "Subnet counts must align with availability_zones (each subnet list length must be <= AZ list length)."
  }
}

variable "enable_nat_gateway" {
  description = "Whether to provision a NAT gateway for private subnet egress"
  type        = bool
  default     = false
}

# Access
variable "ssh_ingress_cidrs" {
  description = "List of source CIDRs allowed to SSH to the host. Must not contain 0.0.0.0/0."
  type        = list(string)
  default     = ["203.0.113.0/24"]

  validation {
    condition     = length(var.ssh_ingress_cidrs) > 0
    error_message = "ssh_ingress_cidrs must contain at least one CIDR."
  }

  validation {
    condition     = alltrue([for c in var.ssh_ingress_cidrs : can(cidrnetmask(c))])
    error_message = "All entries in ssh_ingress_cidrs must be valid IPv4 CIDR blocks."
  }

  validation {
    condition     = alltrue([for c in var.ssh_ingress_cidrs : c != "0.0.0.0/0"])
    error_message = "ssh_ingress_cidrs cannot contain 0.0.0.0/0."
  }
}

variable "ssh_key_name" {
  description = "Existing AWS key pair name for SSH access (leave empty to create one from public_key_path)"
  type        = string
  default     = ""
}

variable "instance_egress_policies" {
  description = "Controlled outbound egress policies for the instance security group"
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [
    {
      description = "HTTPS outbound"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "HTTP outbound"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "DNS TCP outbound"
      from_port   = 53
      to_port     = 53
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "DNS UDP outbound"
      from_port   = 53
      to_port     = 53
      protocol    = "udp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  validation {
    condition = alltrue(flatten([
      for rule in var.instance_egress_policies : [
        for cidr in rule.cidr_blocks : can(cidrnetmask(cidr))
      ]
    ]))
    error_message = "All cidr_blocks in instance_egress_policies must be valid IPv4 CIDRs."
  }
}

variable "public_key_path" {
  description = "Path to a local public key file used to create key pair when key_name is empty"
  type        = string
  default     = ""
}

variable "ssh_user" {
  description = "SSH user for Ansible"
  type        = string
  default     = "ubuntu"
}

# Compute
variable "use_ami_lookup" {
  description = "Use latest Ubuntu AMI lookup when true; otherwise use ami_id"
  type        = bool
  default     = true
}

variable "ami_id" {
  description = "AMI ID for OpenClaw host (leave blank to use latest Ubuntu 22.04 LTS)"
  type        = string
  default     = ""
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.large"
}

variable "root_volume_size_gb" {
  description = "Root EBS volume size in GiB"
  type        = number
  default     = 100

  validation {
    condition     = var.root_volume_size_gb >= 20
    error_message = "root_volume_size_gb must be at least 20 GiB."
  }
}

# Services
variable "openclaw_repo_url" {
  description = "OpenClaw repository URL"
  type        = string
  default     = ""
}

variable "openclaw_repo_ref" {
  description = "OpenClaw repository ref (branch, tag, or commit)"
  type        = string
  default     = "main"
}

variable "ollama_version" {
  description = "Ollama version to install"
  type        = string
  default     = "latest"
}

variable "ollama_model" {
  description = "Default Ollama model to pull"
  type        = string
  default     = ""
}

variable "ollama_bind_host" {
  description = "Ollama bind host"
  type        = string
  default     = "127.0.0.1"
}

variable "ollama_port" {
  description = "Ollama service port"
  type        = number
  default     = 11434
}

# Ops
variable "enable_logging" {
  description = "Enable centralized logging resources/integrations"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Log retention period in days"
  type        = number
  default     = 30
}

variable "enable_monitoring" {
  description = "Enable monitoring resources/integrations"
  type        = bool
  default     = true
}

variable "metrics_retention_days" {
  description = "Metrics retention period in days"
  type        = number
  default     = 15
}

variable "instance_profile_name" {
  description = "Optional existing IAM instance profile name. If empty, one will be created."
  type        = string
  default     = ""
}


variable "enable_ssm" {
  description = "Enable AWS Systems Manager access and required instance permissions"
  type        = bool
  default     = true
}

variable "enable_cloudwatch_agent" {
  description = "Enable CloudWatch agent installation and IAM permissions"
  type        = bool
  default     = false
}

variable "ssm_preferred_access" {
  description = "Prefer SSM-first access by not assigning an SSH key to the instance"
  type        = bool
  default     = false
}

variable "additional_user_data" {
  description = "Optional additional cloud-init shell snippet appended to user_data"
  type        = string
  default     = ""
}

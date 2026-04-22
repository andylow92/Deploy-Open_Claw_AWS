variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

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

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.large"
}

variable "ami_id" {
  description = "AMI ID for OpenClaw host (leave blank to use latest Ubuntu 22.04 LTS)"
  type        = string
  default     = ""
}

variable "allowed_ssh_cidr" {
  description = "Single source CIDR allowed to SSH to host"
  type        = string
  default     = "203.0.113.0/24"

  validation {
    condition     = can(cidrnetmask(var.allowed_ssh_cidr))
    error_message = "allowed_ssh_cidr must be a valid IPv4 CIDR block."
  }

  validation {
    condition     = var.allowed_ssh_cidr != "0.0.0.0/0"
    error_message = "allowed_ssh_cidr cannot be 0.0.0.0/0."
  }
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

variable "key_name" {
  description = "Existing AWS key pair name (optional). If empty and public key path set, key pair will be created."
  type        = string
  default     = ""
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

variable "root_volume_size" {
  description = "Root EBS volume size in GiB"
  type        = number
  default     = 100
}

variable "instance_profile_name" {
  description = "Optional existing IAM instance profile name. If empty, one will be created."
  type        = string
  default     = ""
}

variable "additional_user_data" {
  description = "Optional additional cloud-init shell snippet appended to user_data"
  type        = string
  default     = ""
}

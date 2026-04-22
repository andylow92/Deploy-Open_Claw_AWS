variable "aws_region" {
  description = "AWS region to deploy resources into."
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "aws_region must be a valid AWS region identifier, e.g., us-east-1."
  }
}

variable "project_name" {
  description = "Short project identifier used for naming and tagging resources."
  type        = string
  default     = "openclaw"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9-]{1,30}$", var.project_name))
    error_message = "project_name must start with a letter and contain only letters, numbers, and dashes (2-31 chars)."
  }
}

variable "environment" {
  description = "Deployment environment name (e.g., dev, staging, prod)."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "tags" {
  description = "Additional tags to apply to all supported resources."
  type        = map(string)
  default     = {}
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.10.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "vpc_cidr must be a valid IPv4 CIDR block, e.g., 10.10.0.0/16."
  }
}

variable "public_subnet_cidrs" {
  description = "List of CIDR blocks for public subnets; one per availability zone."
  type        = list(string)
  default     = ["10.10.1.0/24", "10.10.2.0/24"]

  validation {
    condition     = length(var.public_subnet_cidrs) >= 2 && alltrue([for cidr in var.public_subnet_cidrs : can(cidrhost(cidr, 0))])
    error_message = "public_subnet_cidrs must include at least two valid CIDR blocks."
  }
}

variable "private_subnet_cidrs" {
  description = "List of CIDR blocks for private subnets; one per availability zone."
  type        = list(string)
  default     = ["10.10.101.0/24", "10.10.102.0/24"]

  validation {
    condition     = length(var.private_subnet_cidrs) >= 2 && alltrue([for cidr in var.private_subnet_cidrs : can(cidrhost(cidr, 0))])
    error_message = "private_subnet_cidrs must include at least two valid CIDR blocks."
  }
}

variable "availability_zones" {
  description = "Availability zones to use for subnet placement. Must align with subnet list lengths."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]

  validation {
    condition     = length(var.availability_zones) >= 2 && alltrue([for az in var.availability_zones : can(regex("^[a-z]{2}-[a-z]+-[0-9][a-z]$", az))])
    error_message = "availability_zones must include at least two valid AZ names such as us-east-1a."
  }
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH to instances (restrict to trusted IP ranges)."
  type        = string
  default     = "0.0.0.0/0"

  validation {
    condition     = can(cidrhost(var.allowed_ssh_cidr, 0))
    error_message = "allowed_ssh_cidr must be a valid CIDR block."
  }
}

variable "ssh_key_name" {
  description = "Existing AWS EC2 key pair name for SSH access."
  type        = string
  default     = ""

  validation {
    condition     = var.ssh_key_name == "" || can(regex("^[A-Za-z0-9._-]{1,255}$", var.ssh_key_name))
    error_message = "ssh_key_name must be empty or a valid EC2 key pair name."
  }
}

variable "instance_profile_name" {
  description = "Optional existing IAM instance profile name to attach; leave empty to use module-created/default profile logic."
  type        = string
  default     = ""

  validation {
    condition     = var.instance_profile_name == "" || can(regex("^[A-Za-z0-9+=,.@_-]{1,128}$", var.instance_profile_name))
    error_message = "instance_profile_name must be empty or a valid IAM instance profile name."
  }
}

variable "create_instance_profile" {
  description = "Whether Terraform should create an IAM instance profile when instance_profile_name is not provided."
  type        = bool
  default     = true
}

variable "ami_id" {
  description = "Explicit AMI ID to use. Leave null to use SSM lookup when enable_ami_from_ssm is true."
  type        = string
  default     = null

  validation {
    condition     = var.ami_id == null || can(regex("^ami-[a-f0-9]{8,17}$", var.ami_id))
    error_message = "ami_id must be null or a valid AMI ID such as ami-1234567890abcdef0."
  }
}

variable "enable_ami_from_ssm" {
  description = "Whether to look up the AMI ID from AWS Systems Manager Parameter Store when ami_id is null."
  type        = bool
  default     = true
}

variable "instance_type" {
  description = "EC2 instance type for OpenClaw/Ollama host."
  type        = string
  default     = "t3.large"

  validation {
    condition     = can(regex("^[a-z][0-9][a-z]*\\.[a-z0-9]+$", var.instance_type))
    error_message = "instance_type must look like a valid EC2 type, e.g., t3.large."
  }
}

variable "root_volume_size_gb" {
  description = "Root EBS volume size in GiB."
  type        = number
  default     = 50

  validation {
    condition     = var.root_volume_size_gb >= 20 && var.root_volume_size_gb <= 2048
    error_message = "root_volume_size_gb must be between 20 and 2048 GiB."
  }
}

variable "openclaw_repo_url" {
  description = "Git URL for the OpenClaw repository to deploy."
  type        = string
  default     = "https://github.com/example/openclaw.git"

  validation {
    condition     = can(regex("^(https|ssh)://|^git@", var.openclaw_repo_url))
    error_message = "openclaw_repo_url must be a valid HTTPS/SSH git repository URL."
  }
}

variable "openclaw_repo_ref" {
  description = "Git ref (branch, tag, or commit SHA) to checkout for OpenClaw."
  type        = string
  default     = "main"

  validation {
    condition     = length(trim(var.openclaw_repo_ref)) > 0
    error_message = "openclaw_repo_ref cannot be empty."
  }
}

variable "ollama_version" {
  description = "Ollama version to install (or 'latest' if your provisioning supports it)."
  type        = string
  default     = "0.3.14"

  validation {
    condition     = var.ollama_version == "latest" || can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", var.ollama_version))
    error_message = "ollama_version must be 'latest' or semantic version format x.y.z."
  }
}

variable "ollama_model" {
  description = "Default Ollama model to pull and serve."
  type        = string
  default     = "llama3.1:8b"

  validation {
    condition     = length(trim(var.ollama_model)) > 0
    error_message = "ollama_model cannot be empty."
  }
}

variable "ollama_bind_host" {
  description = "Interface for Ollama service binding. Use 127.0.0.1 for local-only access."
  type        = string
  default     = "127.0.0.1"

  validation {
    condition     = contains(["0.0.0.0", "127.0.0.1"], var.ollama_bind_host)
    error_message = "ollama_bind_host must be either 127.0.0.1 or 0.0.0.0."
  }
}

variable "ollama_port" {
  description = "TCP port for Ollama API service."
  type        = number
  default     = 11434

  validation {
    condition     = var.ollama_port >= 1 && var.ollama_port <= 65535
    error_message = "ollama_port must be within 1-65535."
  }
}

variable "enable_cloudwatch_agent" {
  description = "Enable installation and configuration of the CloudWatch Agent."
  type        = bool
  default     = true
}

variable "enable_ssm" {
  description = "Enable AWS Systems Manager (SSM) integration on instances."
  type        = bool
  default     = true
}

variable "ansible_ssh_user" {
  description = "SSH username used by Ansible for configuration management."
  type        = string
  default     = "ec2-user"

  validation {
    condition     = can(regex("^[a-z_][a-z0-9_-]{0,31}$", var.ansible_ssh_user))
    error_message = "ansible_ssh_user must be a valid Linux username format."
  }
}

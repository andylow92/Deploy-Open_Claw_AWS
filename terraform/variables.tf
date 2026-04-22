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
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.42.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.42.11.0/24"]
}

variable "availability_zones" {
  description = "Availability zones used by subnets"
  type        = list(string)
  default     = ["us-east-1a"]
}

variable "enable_nat_gateway" {
  description = "Whether to provision a NAT gateway for private subnet egress"
  type        = bool
  default     = false
}

# Access
variable "allowed_ssh_cidr" {
  description = "Single CIDR allowed to SSH to host"
  type        = string
  default     = "0.0.0.0/0"
}

variable "ssh_key_name" {
  description = "Existing AWS key pair name for SSH access"
  type        = string
  default     = ""
}

variable "enable_ssh" {
  description = "Enable SSH access"
  type        = bool
  default     = true
}

variable "enable_ssm" {
  description = "Enable AWS Systems Manager Session Manager access"
  type        = bool
  default     = true
}

# Backward-compatible access variables
variable "ssh_ingress_cidrs" {
  description = "Source CIDRs allowed to SSH to host"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "key_name" {
  description = "Existing AWS key pair name (deprecated: use ssh_key_name)"
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
}

# Backward-compatible compute variable
variable "root_volume_size" {
  description = "Root EBS volume size in GiB (deprecated: use root_volume_size_gb)"
  type        = number
  default     = 100
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

variable "additional_user_data" {
  description = "Optional additional cloud-init shell snippet appended to user_data"
  type        = string
  default     = ""
}

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

variable "owner" {
  description = "Owner tag value for managed infrastructure"
  type        = string
  default     = "platform"
}

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

variable "ssh_ingress_cidrs" {
  description = "Source CIDRs allowed to SSH to host"
  type        = list(string)
  default     = ["0.0.0.0/0"]
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

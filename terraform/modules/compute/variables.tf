variable "name_prefix" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "security_group_ids" {
  type = list(string)
}

variable "instance_type" {
  type = string
}

variable "ami_id" {
  type    = string
  default = ""
}

variable "key_name" {
  type    = string
  default = ""
}

variable "public_key_path" {
  type    = string
  default = ""
}

variable "ssh_user" {
  type = string
}

variable "root_volume_size" {
  type = number
}

variable "instance_profile_name" {
  type    = string
  default = ""
}

variable "enable_ssm" {
  description = "Whether to enable AWS Systems Manager integration for the instance"
  type        = bool
  default     = true
}

variable "enable_cloudwatch_agent" {
  description = "Whether to install CloudWatch agent and grant it permissions"
  type        = bool
  default     = false
}

variable "ssm_preferred_access" {
  description = "If true, avoid assigning an SSH key to the instance and favor SSM Session Manager access"
  type        = bool
  default     = false
}

variable "additional_user_data" {
  type    = string
  default = ""
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention (in days) for log groups managed by this module."
  type        = number
  default     = 30
}

variable "cloudwatch_agent_version" {
  description = "Amazon CloudWatch agent version folder in the amazoncloudwatch-agent S3 bucket. Set to a specific version (e.g. \"1.300054.0b1096\") to pin; 'latest' is Amazon-maintained but mutable."
  type        = string
  default     = "latest"
}

variable "tags" {
  description = "Common tags applied to compute resources"
  type        = map(string)
  default     = {}
}

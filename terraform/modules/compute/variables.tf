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

variable "additional_user_data" {
  type    = string
  default = ""
}

variable "tags" {
  description = "Common tags applied to compute resources"
  type        = map(string)
  default     = {}
}

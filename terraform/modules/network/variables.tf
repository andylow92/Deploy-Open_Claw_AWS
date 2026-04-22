variable "name_prefix" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "private_subnet_cidrs" {
  type = list(string)
}

variable "availability_zones" {
  type = list(string)
}

variable "enable_nat_gateway" {
  type    = bool
  default = false

  validation {
    condition     = var.enable_nat_gateway ? length(var.public_subnet_cidrs) > 0 : true
    error_message = "enable_nat_gateway requires at least one public subnet."
  }
}

variable "tags" {
  description = "Common tags applied to network resources"
  type        = map(string)
  default     = {}
}

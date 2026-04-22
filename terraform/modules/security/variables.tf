variable "name_prefix" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "ssh_ingress_cidrs" {
  description = "List of source CIDRs allowed to SSH to the host."
  type        = list(string)
}

variable "instance_egress_policies" {
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
}

variable "create_default_nacl" {
  type    = bool
  default = false
}

variable "subnet_ids" {
  type    = list(string)
  default = []
}

variable "tags" {
  description = "Common tags applied to security resources"
  type        = map(string)
  default     = {}
}

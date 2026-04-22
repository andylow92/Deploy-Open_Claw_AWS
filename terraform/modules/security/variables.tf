variable "name_prefix" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "ssh_ingress_cidrs" {
  type = list(string)
}

variable "create_default_nacl" {
  type    = bool
  default = false
}

variable "subnet_ids" {
  type    = list(string)
  default = []
}

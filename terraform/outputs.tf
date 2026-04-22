output "vpc_id" {
  description = "VPC id"
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet ids"
  value       = module.network.public_subnet_ids
}

output "instance_id" {
  description = "EC2 instance id"
  value       = module.compute.instance_id
}

output "instance_public_ip" {
  description = "Public IP for SSH/Ansible"
  value       = module.compute.public_ip
}

output "ssh_user" {
  description = "SSH user for Ansible inventory"
  value       = module.compute.ssh_user
}

output "ansible_host" {
  description = "Preferred host target for Ansible"
  value       = module.compute.public_ip
}

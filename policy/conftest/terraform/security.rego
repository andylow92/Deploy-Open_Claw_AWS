package terraform.security

# Deny broad SSH exposure in security groups.
deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "aws_security_group"
  ingress := resource.change.after.ingress[_]
  ingress.from_port == 22
  ingress.to_port == 22
  ingress.cidr_blocks[_] == "0.0.0.0/0"
  msg := sprintf("Security group %s allows SSH from 0.0.0.0/0", [resource.address])
}

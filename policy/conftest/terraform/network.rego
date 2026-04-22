package terraform.network

# Ensure a VPC is declared in each Terraform plan.
deny[msg] {
  not has_vpc
  msg := "Terraform plan must include at least one aws_vpc resource"
}

has_vpc {
  resource := input.resource_changes[_]
  resource.type == "aws_vpc"
}

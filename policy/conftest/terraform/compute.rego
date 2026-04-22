package terraform.compute

# Ensure compute resources use instance types explicitly.
deny[msg] {
  resource := input.resource_changes[_]
  resource.type == "aws_instance"
  not resource.change.after.instance_type
  msg := sprintf("EC2 instance %s must set instance_type", [resource.address])
}

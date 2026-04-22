environment = "prod"
aws_region  = "us-east-1"

# Restrict SSH ingress to production bastion or enterprise egress ranges.
ssh_ingress_cidrs = ["198.51.100.10/32"]

# Example sizing for production.
instance_type = "m6i.large"

environment = "dev"
aws_region  = "us-east-1"

# Restrict SSH ingress to trusted source ranges.
ssh_ingress_cidrs = ["203.0.113.10/32"]

# Example sizing for development.
instance_type = "t3.large"

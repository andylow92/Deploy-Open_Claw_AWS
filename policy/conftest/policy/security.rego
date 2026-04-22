package terraform.security

import rego.v1

# Required tags that must be present and non-empty on all supported resources.
mandatory_tags := ["Name", "Environment", "Project", "Owner"]

# Ports that are intentionally allowed to be publicly reachable.
allowed_public_inbound_ports := {80, 443}

# Terraform plan resource changes we enforce.
resource_changes := [rc |
	rc := input.resource_changes[_]
	rc.mode == "managed"
	not is_delete(rc)
]

is_delete(rc) if {
	rc.change.actions == ["delete"]
}

after(rc) := rc.change.after

# Rule 1: SSH ingress open to world.
deny contains msg if {
	rc := resource_changes[_]
	rc.type == "aws_security_group"
	r := after(rc)
	ing := r.ingress[_]
	is_world_open(ing)
	port_in_range(ing, 22)
	msg := sprintf("%s allows SSH (22) from 0.0.0.0/0. Restrict ssh_ingress_cidrs to trusted IP ranges.", [rc.address])
}

# Rule 2: Any unintended public inbound ports (except explicit allow-list).
deny contains msg if {
	rc := resource_changes[_]
	rc.type == "aws_security_group"
	r := after(rc)
	ing := r.ingress[_]
	is_world_open(ing)
	public_port := ingress_public_ports(ing)[_]
	not allowed_public_inbound_ports[public_port]
	msg := sprintf("%s exposes public inbound port %v to 0.0.0.0/0. Remove this rule or restrict source CIDRs.", [rc.address, public_port])
}

# Rule 3: Unencrypted root EBS volumes.
deny contains msg if {
	rc := resource_changes[_]
	rc.type == "aws_instance"
	r := after(rc)
	rbd := r.root_block_device[_]
	not rbd.encrypted
	msg := sprintf("%s root_block_device must set encrypted=true.", [rc.address])
}

# Rule 4: IMDSv2 not required.
deny contains msg if {
	rc := resource_changes[_]
	rc.type == "aws_instance"
	r := after(rc)
	not r.metadata_options.http_tokens == "required"
	msg := sprintf("%s must require IMDSv2 via metadata_options.http_tokens=\"required\".", [rc.address])
}

# Rule 5: Missing mandatory tags.
deny contains msg if {
	rc := resource_changes[_]
	requires_tags(rc.type)
	tags := object.get(after(rc), "tags", {})
	tag := mandatory_tags[_]
	value := object.get(tags, tag, "")
	value == ""
	msg := sprintf("%s is missing mandatory tag %q.", [rc.address, tag])
}

requires_tags("aws_instance")
requires_tags("aws_security_group")
requires_tags("aws_network_acl")

is_world_open(ing) if {
	cidrs := object.get(ing, "cidr_blocks", [])
	cidrs[_] == "0.0.0.0/0"
}

port_in_range(ing, p) if {
	from := object.get(ing, "from_port", -1)
	to := object.get(ing, "to_port", -1)
	from <= p
	p <= to
}

ingress_public_ports(ing) := ports if {
	from := object.get(ing, "from_port", -1)
	to := object.get(ing, "to_port", -1)
	ports := {p |
		from != -1
		to != -1
		p := numbers.range(from, to)[_]
	}
}

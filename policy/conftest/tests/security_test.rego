package terraform.security

import rego.v1

base_instance := {
  "ami": "ami-123",
  "instance_type": "t3.micro",
  "metadata_options": {"http_tokens": "required"},
  "root_block_device": [{"encrypted": true}],
  "tags": {
    "Name": "openclaw-host",
    "Environment": "dev",
    "Project": "openclaw",
    "Owner": "platform"
  }
}

base_sg := {
  "ingress": [
    {"from_port": 80, "to_port": 80, "cidr_blocks": ["0.0.0.0/0"]},
    {"from_port": 443, "to_port": 443, "cidr_blocks": ["0.0.0.0/0"]},
    {"from_port": 22, "to_port": 22, "cidr_blocks": ["10.0.0.0/24"]}
  ],
  "tags": {
    "Name": "openclaw-sg",
    "Environment": "dev",
    "Project": "openclaw",
    "Owner": "platform"
  }
}

base_nacl := {
  "tags": {
    "Name": "openclaw-nacl",
    "Environment": "dev",
    "Project": "openclaw",
    "Owner": "platform"
  }
}

mk_input(instance, sg, nacl) := {
  "resource_changes": [
    {
      "address": "module.compute.aws_instance.this",
      "mode": "managed",
      "type": "aws_instance",
      "change": {"actions": ["create"], "after": instance}
    },
    {
      "address": "module.security.aws_security_group.instance",
      "mode": "managed",
      "type": "aws_security_group",
      "change": {"actions": ["create"], "after": sg}
    },
    {
      "address": "module.security.aws_network_acl.default_allow",
      "mode": "managed",
      "type": "aws_network_acl",
      "change": {"actions": ["create"], "after": nacl}
    }
  ]
}

test_deny_empty_for_compliant_plan if {
  input := mk_input(base_instance, base_sg, base_nacl)
  count(deny with input as input) == 0
}

test_deny_for_world_open_ssh if {
  bad_sg := object.union(base_sg, {
    "ingress": [
      {"from_port": 22, "to_port": 22, "cidr_blocks": ["0.0.0.0/0"]}
    ]
  })
  input := mk_input(base_instance, bad_sg, base_nacl)
  some msg in deny with input as input
  contains(msg, "SSH (22)")
}

test_deny_for_unintended_public_port if {
  bad_sg := object.union(base_sg, {
    "ingress": [{"from_port": 3306, "to_port": 3306, "cidr_blocks": ["0.0.0.0/0"]}]
  })
  input := mk_input(base_instance, bad_sg, base_nacl)
  some msg in deny with input as input
  contains(msg, "port 3306")
}

test_deny_for_unencrypted_root_volume if {
  bad_instance := object.union(base_instance, {
    "root_block_device": [{"encrypted": false}]
  })
  input := mk_input(bad_instance, base_sg, base_nacl)
  some msg in deny with input as input
  contains(msg, "encrypted=true")
}

test_deny_for_imdsv2_not_required if {
  bad_instance := object.union(base_instance, {
    "metadata_options": {"http_tokens": "optional"}
  })
  input := mk_input(bad_instance, base_sg, base_nacl)
  some msg in deny with input as input
  contains(msg, "IMDSv2")
}

test_deny_for_missing_mandatory_tags if {
  bad_instance := object.union(base_instance, {
    "tags": {
      "Name": "openclaw-host",
      "Environment": "dev",
      "Project": "openclaw"
    }
  })
  input := mk_input(bad_instance, base_sg, base_nacl)
  some msg in deny with input as input
  contains(msg, "mandatory tag \"Owner\"")
}

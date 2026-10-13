check "subnet_cidr_within_vcn" {
  assert {
    condition = anytrue([
      for cidr in var.vcn_cidr_blocks :
      sum([for i, octet in split(".", cidrhost(cidr, 0)) : tonumber(octet) * pow(256, 3 - i)]) <= sum([for i, octet in split(".", cidrhost(var.subnet_cidr_block, 0)) : tonumber(octet) * pow(256, 3 - i)])
      &&
      sum([for i, octet in split(".", cidrhost(cidr, -1)) : tonumber(octet) * pow(256, 3 - i)]) >= sum([for i, octet in split(".", cidrhost(var.subnet_cidr_block, -1)) : tonumber(octet) * pow(256, 3 - i)])
    ])
    error_message = "subnet_cidr_block (${var.subnet_cidr_block}) must be contained within one of the vcn_cidr_blocks."
  }
}

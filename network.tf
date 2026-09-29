resource "oci_core_vcn" "atlas_vcn" {
  cidr_blocks    = var.vcn_cidr_blocks
  compartment_id = var.compartment_ocid
  display_name   = format("%sVCN", replace(title(var.instance_name), "/\\s/", ""))
  dns_label      = format("%svcn", lower(replace(var.instance_name, "/\\s/", "")))

  freeform_tags = local.tags
}

resource "oci_core_security_list" "atlas_security_list" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.atlas_vcn.id
  display_name   = format("%sSecurityList", replace(title(var.instance_name), "/\\s/", ""))

  # Allow outbound traffic on all ports for all protocols
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
    stateless   = false
  }

  dynamic "ingress_security_rules" {
    for_each = var.ingress_rules
    iterator = rule
    content {
      protocol    = lookup({ tcp = "6", udp = "17", icmp = "1" }, rule.value.protocol, rule.value.protocol)
      source      = rule.value.source
      stateless   = false
      description = rule.value.description

      dynamic "tcp_options" {
        for_each = rule.value.protocol == "tcp" && rule.value.port != null ? [1] : []
        content {
          min = rule.value.port
          max = rule.value.port
        }
      }

      dynamic "udp_options" {
        for_each = rule.value.protocol == "udp" && rule.value.port != null ? [1] : []
        content {
          min = rule.value.port
          max = rule.value.port
        }
      }
    }
  }

  # Allow inbound icmp traffic of a specific type
  ingress_security_rules {
    protocol  = 1
    source    = "0.0.0.0/0"
    stateless = false

    icmp_options {
      type = 3
      code = 4
    }
  }

  freeform_tags = local.tags
}

resource "oci_core_internet_gateway" "atlas_internet_gateway" {
  compartment_id = var.compartment_ocid
  display_name   = format("%sIGW", replace(title(var.instance_name), "/\\s/", ""))
  vcn_id         = oci_core_vcn.atlas_vcn.id

  freeform_tags = local.tags
}

resource "oci_core_default_route_table" "default_route_table" {
  manage_default_resource_id = oci_core_vcn.atlas_vcn.default_route_table_id
  display_name               = "DefaultRouteTable"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.atlas_internet_gateway.id
  }

  freeform_tags = local.tags
}

resource "oci_core_subnet" "atlas_subnet" {
  cidr_block        = var.subnet_cidr_block
  display_name      = format("%sSubnet", replace(title(var.instance_name), "/\\s/", ""))
  dns_label         = format("%ssubnet", lower(replace(var.instance_name, "/\\s/", "")))
  security_list_ids = [oci_core_security_list.atlas_security_list.id]
  compartment_id    = var.compartment_ocid
  vcn_id            = oci_core_vcn.atlas_vcn.id
  route_table_id    = oci_core_vcn.atlas_vcn.default_route_table_id
  dhcp_options_id   = oci_core_vcn.atlas_vcn.default_dhcp_options_id

  freeform_tags = local.tags
}

data "oci_core_vnic_attachments" "instance_primary" {
  count          = var.assign_public_ip && var.public_ip == "RESERVED" ? var.num_instances : 0
  compartment_id = var.compartment_ocid
  instance_id    = oci_core_instance.atlas_instance[count.index].id
}

data "oci_core_private_ips" "instance_primary" {
  count   = var.assign_public_ip && var.public_ip == "RESERVED" ? var.num_instances : 0
  vnic_id = data.oci_core_vnic_attachments.instance_primary[count.index].vnic_attachments[0].vnic_id
}

resource "oci_core_public_ip" "reserved" {
  count          = var.assign_public_ip && var.public_ip == "RESERVED" ? var.num_instances : 0
  compartment_id = var.compartment_ocid
  lifetime       = "RESERVED"
  display_name   = format("%sPublicIP%d", title(replace(var.instance_name, "/\\s/", "")), count.index)
  private_ip_id  = data.oci_core_private_ips.instance_primary[count.index].private_ips[0].id

  freeform_tags = local.tags
}

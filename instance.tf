resource "oci_core_instance" "atlas_instance" {
  count               = var.num_instances
  availability_domain = var.spread_across_ads ? element(data.oci_identity_availability_domains.ads.availability_domains, count.index).name : element(data.oci_identity_availability_domains.ads.availability_domains, var.instance_ad_number).name
  compartment_id      = var.compartment_ocid
  display_name        = format("%s%d", title(replace(var.instance_name, "/\\s/", "")), count.index)
  shape               = var.instance_shape

  dynamic "shape_config" {
    for_each = strcontains(var.instance_shape, "Flex") ? [1] : []
    content {
      ocpus         = var.instance_ocpus
      memory_in_gbs = var.instance_shape_config_memory_in_gbs
    }
  }

  create_vnic_details {
    subnet_id                 = oci_core_subnet.atlas_subnet.id
    display_name              = format("%sVNIC", title(replace(var.instance_name, "/\\s/", "")))
    assign_public_ip          = var.assign_public_ip
    assign_private_dns_record = true
    hostname_label            = format("%s%d", lower(replace(var.instance_name, "/\\s/", "")), count.index)
  }

  source_details {
    source_type             = var.instance_source_type
    source_id               = coalesce(try(var.instance_image_ocid[var.region], null), try(data.oci_core_images.this.images[0].id, null))
    boot_volume_size_in_gbs = var.boot_volume_size_in_gbs
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_keys
  }

  timeouts {
    create = "60m"
  }
}

data "oci_core_instance_devices" "atlas_instance_devices" {
  count       = var.num_instances
  instance_id = oci_core_instance.atlas_instance[count.index].id
}

data "oci_identity_availability_domains" "ads" {
  compartment_id = var.tenancy_ocid
}

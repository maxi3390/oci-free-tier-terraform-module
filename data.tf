data "oci_core_instance_devices" "atlas_instance_devices" {
  count       = var.num_instances
  instance_id = oci_core_instance.atlas_instance[count.index].id
}

data "oci_identity_availability_domains" "ads" {
  compartment_id = coalesce(var.tenancy_ocid, var.compartment_ocid)
}

data "oci_core_images" "this" {
  compartment_id           = var.compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = var.image_os_version
  shape                    = var.instance_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

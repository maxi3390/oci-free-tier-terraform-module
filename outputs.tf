output "instance_private_ips" {
  value = [oci_core_instance.atlas_instance.*.private_ip]
}

output "instance_public_ips" {
  value = [oci_core_instance.atlas_instance.*.public_ip]
}

output "boot_volume_ids" {
  value = [oci_core_instance.atlas_instance.*.boot_volume_id]
}

output "instance_devices" {
  value = [data.oci_core_instance_devices.atlas_instance_devices.*.devices]
}
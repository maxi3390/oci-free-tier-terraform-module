output "instance_private_ips" {
  value     = oci_core_instance.atlas_instance[*].private_ip
  sensitive = true
}

output "instance_public_ips" {
  value = oci_core_instance.atlas_instance[*].public_ip
}

output "reserved_public_ips" {
  value = [for ip in oci_core_public_ip.reserved : ip.ip_address]
}

output "boot_volume_ids" {
  value = oci_core_instance.atlas_instance[*].boot_volume_id
}

output "instance_devices" {
  value = [for devices in data.oci_core_instance_devices.atlas_instance_devices : devices.devices]
}

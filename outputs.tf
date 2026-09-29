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

output "bucket_names" {
  value = [for bucket in oci_objectstorage_bucket.this : bucket.name]
}

output "bucket_ids" {
  value = [for bucket in oci_objectstorage_bucket.this : bucket.id]
}

output "instance_ocids" {
  value = oci_core_instance.atlas_instance[*].id
}

output "vcn_id" {
  value = oci_core_vcn.atlas_vcn.id
}

output "subnet_id" {
  value = oci_core_subnet.atlas_subnet.id
}

output "security_list_id" {
  value = oci_core_security_list.atlas_security_list.id
}

output "autonomous_database_id" {
  value = var.autonomous_database_enabled ? oci_database_autonomous_database.this[0].id : null
}

output "autonomous_database_connection_strings" {
  value = var.autonomous_database_enabled ? oci_database_autonomous_database.this[0].connection_strings : null
}

output "autonomous_database_admin_password" {
  description = "ADMIN password for the Autonomous Database (the generated one when autonomous_database_admin_password was unset)."
  value       = var.autonomous_database_enabled ? coalesce(var.autonomous_database_admin_password, try(random_password.adb_admin[0].result, null)) : null
  sensitive   = true
}

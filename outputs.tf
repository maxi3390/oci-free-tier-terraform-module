output "instance_private_ips" {
  description = "Private IP addresses of the instances."
  value       = oci_core_instance.atlas_instance[*].private_ip
  sensitive   = true
}

output "instance_public_ips" {
  description = "Public IP addresses of the instances (empty when assign_public_ip is false)."
  value       = oci_core_instance.atlas_instance[*].public_ip
}

output "reserved_public_ips" {
  description = "Reserved public IP addresses attached to the instances (public_ip = \"RESERVED\")."
  value       = [for ip in oci_core_public_ip.reserved : ip.ip_address]
}

output "boot_volume_ids" {
  description = "OCIDs of the instances' boot volumes."
  value       = oci_core_instance.atlas_instance[*].boot_volume_id
}

output "instance_devices" {
  description = "Block storage devices attached to each instance."
  value       = [for devices in data.oci_core_instance_devices.atlas_instance_devices : devices.devices]
}

output "bucket_names" {
  description = "Names of the created Object Storage buckets."
  value       = [for bucket in oci_objectstorage_bucket.this : bucket.name]
}

output "bucket_ids" {
  description = "OCIDs of the created Object Storage buckets."
  value       = [for bucket in oci_objectstorage_bucket.this : bucket.id]
}

output "instance_ocids" {
  description = "OCIDs of the instances."
  value       = oci_core_instance.atlas_instance[*].id
}

output "vcn_id" {
  description = "OCID of the VCN created for the deployment."
  value       = oci_core_vcn.atlas_vcn.id
}

output "subnet_id" {
  description = "OCID of the subnet created for the deployment."
  value       = oci_core_subnet.atlas_subnet.id
}

output "security_list_id" {
  description = "OCID of the security list controlling the subnet's ingress/egress rules."
  value       = oci_core_security_list.atlas_security_list.id
}

output "autonomous_database_id" {
  description = "OCID of the Autonomous Database (null when disabled)."
  value       = var.autonomous_database_enabled ? oci_database_autonomous_database.this[0].id : null
}

output "autonomous_database_connection_strings" {
  description = "Connection strings of the Autonomous Database (null when disabled)."
  value       = var.autonomous_database_enabled ? oci_database_autonomous_database.this[0].connection_strings : null
}

output "autonomous_database_admin_password" {
  description = "ADMIN password for the Autonomous Database (the generated one when autonomous_database_admin_password was unset)."
  value       = var.autonomous_database_enabled ? coalesce(var.autonomous_database_admin_password, try(random_password.adb_admin[0].result, null)) : null
  sensitive   = true
}

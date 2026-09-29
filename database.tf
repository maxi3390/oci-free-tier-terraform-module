resource "oci_database_autonomous_database" "this" {
  count = var.autonomous_database_enabled ? 1 : 0

  compartment_id           = var.compartment_ocid
  display_name             = var.autonomous_database_display_name
  db_name                  = replace(lower(var.autonomous_database_display_name), "/[^a-z0-9]/", "")
  db_workload              = var.autonomous_database_workload
  is_free_tier             = true
  cpu_core_count           = 1
  data_storage_size_in_tbs = 1
  admin_password           = var.autonomous_database_admin_password

  is_auto_scaling_enabled = false
  freeform_tags           = local.tags
}

resource "random_password" "adb_admin" {
  count       = var.autonomous_database_enabled && var.autonomous_database_admin_password == null ? 1 : 0
  length      = 20
  min_upper   = 1
  min_lower   = 1
  min_numeric = 1
  special     = false
}

resource "oci_database_autonomous_database" "this" {
  count = var.autonomous_database_enabled ? 1 : 0

  compartment_id           = var.compartment_ocid
  display_name             = var.autonomous_database_display_name
  db_name                  = replace(lower(var.autonomous_database_display_name), "/[^a-z0-9]/", "")
  db_workload              = var.autonomous_database_workload
  is_free_tier             = true
  cpu_core_count           = 1
  data_storage_size_in_tbs = 1
  admin_password           = coalesce(var.autonomous_database_admin_password, try(random_password.adb_admin[0].result, null))

  is_auto_scaling_enabled = false
  freeform_tags           = local.tags
}

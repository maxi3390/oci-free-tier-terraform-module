data "oci_objectstorage_namespace" "ns" {
  compartment_id = var.compartment_ocid
}

resource "oci_objectstorage_bucket" "this" {
  for_each = var.object_storage_enabled ? { for bucket in var.object_storage_buckets : bucket.name => bucket } : {}

  compartment_id = var.compartment_ocid
  namespace      = data.oci_objectstorage_namespace.ns.namespace
  name           = each.key
  storage_tier   = each.value.storage_tier
  versioning     = each.value.versioning
  freeform_tags  = local.tags
}

check "free_tier_a1_ocpus" {
  assert {
    condition     = !strcontains(var.instance_shape, "A1") || var.num_instances * var.instance_ocpus <= 4
    error_message = "The Always Free A1 budget is 4 OCPUs in total across all instances (num_instances × instance_ocpus exceeds it)."
  }
}

check "free_tier_a1_memory" {
  assert {
    condition     = !strcontains(var.instance_shape, "A1") || var.num_instances * var.instance_shape_config_memory_in_gbs <= 24
    error_message = "The Always Free A1 budget is 24 GB of memory in total across all instances (num_instances × instance_shape_config_memory_in_gbs exceeds it)."
  }
}

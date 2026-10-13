mock_provider "oci" {
  mock_data "oci_core_images" {
    defaults = {
      images = [{ id = "ocid1.image.oc1..aaaaaaaaexample" }]
    }
  }

  mock_data "oci_identity_availability_domains" {
    defaults = {
      availability_domains = [{ name = "AD-1" }]
    }
  }
}

run "minimal_config_plans_clean" {
  command = plan

  variables {
    compartment_ocid = "ocid1.compartment.oc1..aaaaaaaaexample"
    instance_name    = "atlas"
  }
}

run "boot_volume_total_over_200_fails" {
  command = plan

  variables {
    compartment_ocid        = "ocid1.compartment.oc1..aaaaaaaaexample"
    instance_name           = "atlas"
    num_instances           = 2
    boot_volume_size_in_gbs = 101
  }

  expect_failures = [var.boot_volume_size_in_gbs]
}

run "boot_volume_total_exactly_200_passes" {
  command = plan

  variables {
    compartment_ocid        = "ocid1.compartment.oc1..aaaaaaaaexample"
    instance_name           = "atlas"
    num_instances           = 2
    boot_volume_size_in_gbs = 100
  }
}

run "boot_volume_below_minimum_fails" {
  command = plan

  variables {
    compartment_ocid        = "ocid1.compartment.oc1..aaaaaaaaexample"
    instance_name           = "atlas"
    boot_volume_size_in_gbs = 46
  }

  expect_failures = [var.boot_volume_size_in_gbs]
}

run "a1_ocpu_budget_fails" {
  command = plan

  variables {
    compartment_ocid = "ocid1.compartment.oc1..aaaaaaaaexample"
    instance_name    = "atlas"
    num_instances    = 2
    instance_ocpus   = 2
  }

  expect_failures = [var.instance_ocpus]
}

run "a1_memory_budget_fails" {
  command = plan

  variables {
    compartment_ocid                    = "ocid1.compartment.oc1..aaaaaaaaexample"
    instance_name                       = "atlas"
    num_instances                       = 2
    instance_shape_config_memory_in_gbs = 12
  }

  expect_failures = [var.instance_shape_config_memory_in_gbs]
}

run "more_than_two_instances_fails" {
  command = plan

  variables {
    compartment_ocid                    = "ocid1.compartment.oc1..aaaaaaaaexample"
    instance_name                       = "atlas"
    num_instances                       = 3
    instance_shape_config_memory_in_gbs = 4
    boot_volume_size_in_gbs             = 49
  }

  expect_failures = [var.num_instances]
}

run "more_than_two_e2_micro_instances_fails" {
  command = plan

  variables {
    compartment_ocid = "ocid1.compartment.oc1..aaaaaaaaexample"
    instance_name    = "atlas"
    instance_shape   = "VM.Standard.E2.1.Micro"
    num_instances    = 3
  }

  expect_failures = [var.num_instances]
}

run "free_tier_limits_disabled_allows_overage" {
  command = plan

  variables {
    compartment_ocid                    = "ocid1.compartment.oc1..aaaaaaaaexample"
    instance_name                       = "atlas"
    enforce_free_tier_limits            = false
    num_instances                       = 2
    instance_ocpus                      = 2
    instance_shape_config_memory_in_gbs = 12
    boot_volume_size_in_gbs             = 100
  }
}

run "instance_name_too_long_fails" {
  command = plan

  variables {
    compartment_ocid = "ocid1.compartment.oc1..aaaaaaaaexample"
    instance_name    = "waytoolongname"
  }

  expect_failures = [var.instance_name]
}

run "subnet_outside_vcn_check_fails" {
  command = plan

  variables {
    compartment_ocid  = "ocid1.compartment.oc1..aaaaaaaaexample"
    instance_name     = "atlas"
    vcn_cidr_blocks   = ["10.1.0.0/16"]
    subnet_cidr_block = "192.168.5.0/24"
  }

  expect_failures = [check.subnet_cidr_within_vcn]
}

run "adb_password_generated_when_unset" {
  command = plan

  variables {
    compartment_ocid            = "ocid1.compartment.oc1..aaaaaaaaexample"
    instance_name               = "atlas"
    autonomous_database_enabled = true
  }
}

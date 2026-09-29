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
    boot_volume_size_in_gbs = 100
  }

  expect_failures = [var.boot_volume_size_in_gbs]
}

run "a1_ocpu_budget_check_fails" {
  command = plan

  variables {
    compartment_ocid        = "ocid1.compartment.oc1..aaaaaaaaexample"
    instance_name           = "atlas"
    num_instances           = 3
    instance_ocpus          = 2
    boot_volume_size_in_gbs = 49
  }

  expect_failures = [check.free_tier_a1_ocpus]
}

run "a1_memory_budget_check_fails" {
  command = plan

  variables {
    compartment_ocid                    = "ocid1.compartment.oc1..aaaaaaaaexample"
    instance_name                       = "atlas"
    num_instances                       = 3
    instance_shape_config_memory_in_gbs = 12
    boot_volume_size_in_gbs             = 49
  }

  expect_failures = [check.free_tier_a1_memory]
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

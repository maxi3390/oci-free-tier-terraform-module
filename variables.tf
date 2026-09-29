variable "fingerprint" {
  description = "Fingerprint of oci api private key. Leave unset to use the OCI CLI configuration file (~/.oci/config)."
  type        = string
  default     = null
  sensitive   = true
}

variable "private_key_path" {
  description = "Path to oci api private key used. Leave unset to use the OCI CLI configuration file (~/.oci/config)."
  type        = string
  default     = null
  sensitive   = true
}

variable "region" {
  description = "The oci region where resources will be created. Leave unset to use the region from the OCI CLI configuration file (~/.oci/config)."
  type        = string
  default     = null
}

variable "tenancy_ocid" {
  description = "Tenancy ocid where to create the sources. Leave unset to use the OCI CLI configuration file (~/.oci/config)."
  type        = string
  default     = null
}

variable "user_ocid" {
  description = "Ocid of user that terraform will use to create the resources. Leave unset to use the OCI CLI configuration file (~/.oci/config)."
  type        = string
  default     = null
}

variable "compartment_ocid" {
  description = "Compartment ocid where to create all resources"
  type        = string
}

variable "instance_name" {
  description = "Name of the instance. Used to derive resource display names and DNS labels, so it must be short and alphanumeric."
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9]{0,10}$", var.instance_name))
    error_message = "instance_name must start with a letter, contain only alphanumerics, and be at most 11 characters long so the derived DNS labels stay within OCI's 15-character limit."
  }
}

variable "instance_ad_number" {
  default     = 0
  description = "Zero-based index of the availability domain to launch the instance in. Wraps around (round-robin) when the region has fewer availability domains."
  type        = number

  validation {
    condition     = var.instance_ad_number >= 0
    error_message = "instance_ad_number must be a zero-based availability domain index (0 for the first AD)."
  }
}

variable "ssh_public_keys" {
  default     = null
  description = "Public SSH keys to be included in the ~/.ssh/authorized_keys file for the default user on the instance. To provide multiple keys, see docs/instance_ssh_keys.adoc."
  type        = string
  sensitive   = true
}

variable "ssh_private_key" {
  default     = null
  description = "Private SSH key for remote execution."
  type        = string
  sensitive   = true

  validation {
    condition     = !var.auto_iptables || var.ssh_private_key != null
    error_message = "ssh_private_key is required when auto_iptables is true."
  }
}

variable "auto_iptables" {
  default     = false
  description = "Automatically configure iptables to allow inbound traffic."
  type        = bool
}

variable "vcn_cidr_blocks" {
  description = "The deployment vcn cidr block (e.g., ['10.1.0.0/16', '172.30.0.0/20'])"
  type        = list(string)
  default     = ["10.1.0.0/16"]
}

variable "subnet_cidr_block" {
  description = "The deployment subnet cidr block (e.g., '10.1.20.0/24')"
  type        = string
  default     = "10.1.20.0/24"
}

variable "assign_public_ip" {
  default     = false
  description = "Whether the VNIC should be assigned a public IP address. Required for the auto_iptables remote-exec step and for public_ip = \"RESERVED\"."
  type        = bool
}

variable "public_ip" {
  default     = "NONE"
  description = "Lifetime of the public IP attached to the primary VNIC. Valid values are NONE, RESERVED or EPHEMERAL. EPHEMERAL addresses change on stop/start; RESERVED ones are free while attached and survive reboots."
  type        = string

  validation {
    condition     = contains(["NONE", "RESERVED", "EPHEMERAL"], var.public_ip)
    error_message = "Accepted values are NONE, RESERVED or EPHEMERAL."
  }

  validation {
    condition     = var.public_ip != "RESERVED" || var.assign_public_ip
    error_message = "public_ip = \"RESERVED\" requires assign_public_ip = true."
  }
}

variable "freeform_tags" {
  description = "Freeform tags applied to all created resources (merged over the default { ManagedBy = \"terraform\" })."
  type        = map(string)
  default     = {}
}

variable "ingress_rules" {
  description = "Inbound security list rules. Default allows SSH from anywhere. protocol accepts tcp, udp, icmp, all (or a protocol number); port applies to tcp/udp."
  type = list(object({
    protocol    = string
    port        = optional(number)
    source      = string
    description = optional(string)
  }))
  default = [{ protocol = "tcp", port = 22, source = "0.0.0.0/0" }]
}

variable "num_instances" {
  default = 1
  type    = number
}

variable "instance_shape" {
  default     = "VM.Standard.A1.Flex"
  description = "The shape of an instance."
  type        = string
}

variable "instance_ocpus" {
  default     = 1
  description = "Number of OCPUs"
  type        = number
}

variable "instance_shape_config_memory_in_gbs" {
  default     = 6
  description = "Amount of Memory (GB)"
  type        = number
}

variable "instance_source_type" {
  default     = "image"
  description = "The source type for the instance."
  type        = string

  validation {
    condition     = var.instance_source_type == "image"
    error_message = "Only the \"image\" source type is supported."
  }
}

variable "boot_volume_size_in_gbs" {
  default     = "100"
  description = "Boot volume size in GBs per instance. The Always Free tier includes 200 GB of block storage in total, so num_instances × boot_volume_size_in_gbs must stay below 200."
  type        = number

  validation {
    condition     = var.num_instances * var.boot_volume_size_in_gbs < 200
    error_message = "The Always Free tier includes 200 GB of block storage in total. num_instances × boot_volume_size_in_gbs must stay below 200 GB (e.g. 2 × 99 or 4 × 49)."
  }
}

variable "instance_image_ocid" {
  description = "Optional per-region image OCID overrides (e.g. { \"us-ashburn-1\" = \"ocid1.image...\"). When unset, the latest Canonical Ubuntu image compatible with the shape is selected automatically."
  type        = map(string)
  default     = {}
}

variable "image_os_version" {
  description = "Operating system version used when selecting the image automatically (e.g. \"24.04\")."
  type        = string
  default     = "24.04"
}

variable "spread_across_ads" {
  description = "Distribute instances round-robin across all availability domains instead of pinning them to instance_ad_number. Improves odds against Out of Capacity in multi-instance deploys."
  type        = bool
  default     = false
}

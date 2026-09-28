variable "fingerprint" {
  description = "Fingerprint of oci api private key. Leave unset to use the OCI CLI configuration file (~/.oci/config)."
  type        = string
  default     = null
}

variable "private_key_path" {
  description = "Path to oci api private key used. Leave unset to use the OCI CLI configuration file (~/.oci/config)."
  type        = string
  default     = null
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
  description = "Name of the instance."
  type        = string
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

variable "instance_count" {
  default     = 1
  description = "Number of identical instances to launch from a single module."
  type        = number
}

variable "instance_state" {
  default     = "RUNNING"
  description = "(Updatable) The target state for the instance. Could be set to RUNNING or STOPPED."
  type        = string

  validation {
    condition     = contains(["RUNNING", "STOPPED"], var.instance_state)
    error_message = "Accepted values are RUNNING or STOPPED."
  }
}

variable "ssh_public_keys" {
  default     = null
  description = "Public SSH keys to be included in the ~/.ssh/authorized_keys file for the default user on the instance. To provide multiple keys, see docs/instance_ssh_keys.adoc."
  type        = string
}

variable "ssh_private_key" {
  default     = null
  description = "Private SSH key for remote execution."
  type        = string
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
  description = "Whether the VNIC should be assigned a public IP address."
  type        = bool
}

variable "public_ip" {
  default     = "NONE"
  description = "Whether to create a Public IP to attach to primary vnic and which lifetime. Valid values are NONE, RESERVED or EPHEMERAL."
  type        = string
}

variable "num_instances" {
  default = "1"
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

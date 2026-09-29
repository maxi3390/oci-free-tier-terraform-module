# OCI-FREE-TIER-TERRAFORM-MODULE

Personalized compute instance deployment configuration for Oracle Cloud Infrastructure provider.

### Always Free Tier Limitations [(source)](https://docs.oracle.com/en-us/iaas/Content/FreeTier/freetier_topic-Always_Free_Resources.htm#freetier_topic_Always_Free_Resources_Infrastructure)

> **Micro instances (AMD processor)**: All tenancies get two Always Free VM instances using the VM.Standard.E2.1.Micro shape, which has an AMD processor.

> **Ampere A1 Compute instances (Arm processor)**: All tenancies get the first 3,000 OCPU hours and 18,000 GB hours per month for free for VM instances using the VM.Standard.A1.Flex shape, which has an Arm processor. For Always Free tenancies, this is equivalent to 4 OCPUs and 24 GB of memory.

You can also distribute this resources equally into multiple instances by configuring the variables like in the examples below.

```hcl
# One instance
num_instances                       = 1
instance_ocpus                      = 4
instance_shape_config_memory_in_gbs = 24

# Two instances
num_instances                       = 2
instance_ocpus                      = 2
instance_shape_config_memory_in_gbs = 12

# Four instances
num_instances                       = 4
instance_ocpus                      = 1
instance_shape_config_memory_in_gbs = 6
```

## Minimal configuration

If you have the [OCI CLI configured](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm) (`~/.oci/config`), the only required variables are:

```hcl
compartment_ocid = "<compartment OCID>"
instance_name    = "Atlas"
ssh_public_keys  = "<ssh public key>"
```

The provider authentication variables (`tenancy_ocid`, `user_ocid`, `fingerprint`, `private_key_path`, `region`) are optional and fall back to the OCI CLI configuration file. See `terraform.tfvars.example` for the full list.

Instances are placed in availability domain `instance_ad_number` (zero-based, default `0`); the index wraps around in regions with fewer availability domains. Set `spread_across_ads = true` to distribute instances round-robin across all availability domains instead — this improves the odds against "Out of Capacity" in multi-instance deploys. Both Flex shapes (e.g. `VM.Standard.A1.Flex`) and non-Flex shapes (e.g. `VM.Standard.E2.1.Micro`) are supported; OCPU/memory configuration is only applied to Flex shapes.

The latest Canonical Ubuntu image compatible with the shape is selected automatically (`image_os_version`, default `24.04`). To pin a specific image, set `instance_image_ocid` as a per-region map:

```hcl
instance_image_ocid = { "us-ashburn-1" = "ocid1.image.oc1.iad.aaaa..." }
```

The image is pinned at creation time: OCI does not allow changing the image of a running instance, so later plans will not propose image updates even when a newer Ubuntu release is published. To move to a newer image, replace the instance explicitly:

```bash
terraform apply -replace="oci_core_instance.atlas_instance[0]"
```

## Free tier limits

The module validates your configuration against the Always Free allowances:

- **Block storage (hard limit)**: 200 GB in total. `num_instances × boot_volume_size_in_gbs` must stay below 200 (e.g. `2 × 99` or `4 × 49`); plans exceeding it fail validation.
- **A1 budget (warnings)**: 4 OCPUs and 24 GB of memory in total across all instances. Exceeding these emits a warning during plan (useful if you also consume the budget outside this module).

All created resources are tagged with `ManagedBy = "terraform"` plus anything you pass to `freeform_tags`.

## Optional add-ons

Both features below are fully optional and disabled by default; the default deploy creates none of them.

### Object Storage

```hcl
object_storage_enabled = true
object_storage_buckets = [
  { name = "my-backups", storage_tier = "Standard" },
  { name = "my-archive", storage_tier = "Archive", versioning = "Enabled" },
]
```

The Always Free tier includes 10 GB of Standard and 10 GB of Archive object storage. A bucket created here can also serve as the Terraform state backend described above.

### Autonomous Database

```hcl
autonomous_database_enabled        = true
autonomous_database_workload       = "OLTP" # or "DW"
autonomous_database_admin_password = "<12-30 chars, upper, lower and digit>"
```

Creates one Always Free Autonomous Database (`is_free_tier = true`, 1 OCPU, auto-scaling disabled) with a public endpoint. The free allowance is 2 databases with 20 GB each; this module creates one.

`autonomous_database_admin_password` is optional: when unset, a policy-compliant password is generated automatically and exposed through the `autonomous_database_admin_password` output (marked sensitive).

## Helper script `out-of-capacity.sh`

Out of capacity is a common error when trying to create an instance in OCI provider using the Always Free tier, this little helper script will try to apply the terraform plan until it succeeds.

It retries with a delay and gives up after a maximum number of attempts, both configurable through environment variables:

```bash
MAX_ATTEMPTS=30 SLEEP_SECONDS=60 ./out-of-capacity.sh
```

### Suggestion

Before trying the `out-of-capacity` helper right away, try gradually upgrading the `instance_ocpus` and `instance_shape_config_memory_in_gbs` starting from the minimum requirements, and run this script only after when you encounter the error "Out of Capacity".

## State Storage Backend

After the successful creation of the desired instance, it would be better to persist the state by migrating to a remote backend. For this need, you can use Oracle's AWS S3 compatible Bucket Service's versioned Always Free Tier to store the state file, you can follow [the official guideline](https://developer.hashicorp.com/terraform/language/backend/oci).

```hcl
# main_override.tf
terraform {
  backend "oci" {
    # Required
    bucket                      = "<Bucket>"
    namespace                   = "<Namespace>"
    # Optional
    key                         = "<Key/PathOnBucket>"
    region                      = "<Region>"
  }
}
```

After the change, init once again to reflect the backend change, it should be prompt a dialog to migrate the old state file to OCI backend.

```bash
$ terraform init
$ terraform apply -auto-approve
```

## Allow Inbound Traffic

By default the security list only allows inbound SSH (port 22) from anywhere, plus ICMP path-MTU traffic. Additional inbound rules are configured through `ingress_rules`:

```hcl
ingress_rules = [
  { protocol = "tcp", port = 80,  source = "0.0.0.0/0" },
  { protocol = "tcp", port = 443, source = "0.0.0.0/0" },
]
```

To allow inbound traffic from anywhere on the instance itself you also have to delete an INPUT REJECT rule from the host iptables. If you choose to do these steps automatically, a remote-exec step is configured to handle this process if you set `auto_iptables` and `ssh_private_key` variables under the `terraform.tfvars`. Note that `auto_iptables` requires a public IP (`assign_public_ip = true`).

### Public IP lifetime

Ephemeral public IPs change on every stop/start. Set `public_ip = "RESERVED"` (with `assign_public_ip = true`) to attach a reserved public IP, which is free while attached and survives reboots:

```hcl
assign_public_ip = true
public_ip        = "RESERVED"
```

### Restrict SSH to your current IP

If your public IP changes over time, `update-ssh-ingress.sh` rewrites the SSH ingress rule of the security list so it only allows connections from the machine's current public IP. Wire it into cron so it runs daily (midnight in the example):

```bash
0 0 * * * SECURITY_LIST_OCID="<security list OCID>" /path/to/update-ssh-ingress.sh >> "$HOME/.update-ssh-ingress.log" 2>&1
```

Get the OCID with `terraform output -raw security_list_id`. The script requires the OCI CLI, `jq` and `curl`. Note that the security list is managed by Terraform: the next `terraform apply` reverts the SSH source to your `ingress_rules` value.

### Automatic execution
```bash
auto_iptables   = true
ssh_private_key = "~/.ssh/id_rsa"
```

### Manual execution
```bash
$ # Backup the current iptables configuration.
$ iptables -L > ~/iptables.bak
$ # Find and delete the line number that contains the "REJECT anywhere anywhere" from the Chain INPUT.
$ iptables -L --line-numbers
$ iptables -D INPUT <LINE_NUMBER>
$ # Preserve the iptables rules.
$ iptables-save > /etc/iptables/rules.v4
```

Pending improvements are tracked in [TODO.md](TODO.md).

## Reference

The tables below are auto-generated with [terraform-docs](https://terraform-docs.io) (`terraform-docs .`, config in `.terraform-docs.yml`); they include every module output, such as `instance_ocids`, `vcn_id`, `subnet_id` and `security_list_id`.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_oci"></a> [oci](#requirement\_oci) | ~> 7.17 |
| <a name="requirement_random"></a> [random](#requirement\_random) | ~> 3.7 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_oci"></a> [oci](#provider\_oci) | 7.32.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.9.1 |
| <a name="provider_terraform"></a> [terraform](#provider\_terraform) | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [oci_core_default_route_table.default_route_table](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_default_route_table) | resource |
| [oci_core_instance.atlas_instance](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_instance) | resource |
| [oci_core_internet_gateway.atlas_internet_gateway](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_internet_gateway) | resource |
| [oci_core_public_ip.reserved](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_public_ip) | resource |
| [oci_core_security_list.atlas_security_list](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_security_list) | resource |
| [oci_core_subnet.atlas_subnet](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_subnet) | resource |
| [oci_core_vcn.atlas_vcn](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/core_vcn) | resource |
| [oci_database_autonomous_database.this](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/database_autonomous_database) | resource |
| [oci_objectstorage_bucket.this](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/objectstorage_bucket) | resource |
| [random_password.adb_admin](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [terraform_data.iptables](https://registry.terraform.io/providers/hashicorp/terraform/latest/docs/resources/data) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_assign_public_ip"></a> [assign\_public\_ip](#input\_assign\_public\_ip) | Whether the VNIC should be assigned a public IP address. Required for the auto\_iptables remote-exec step and for public\_ip = "RESERVED". | `bool` | `false` | no |
| <a name="input_auto_iptables"></a> [auto\_iptables](#input\_auto\_iptables) | Automatically configure iptables to allow inbound traffic. | `bool` | `false` | no |
| <a name="input_autonomous_database_admin_password"></a> [autonomous\_database\_admin\_password](#input\_autonomous\_database\_admin\_password) | ADMIN user password for the Autonomous Database. Must follow the OCI password policy (12-30 chars, upper, lower and digit). When unset, a compliant password is generated automatically and exposed via the autonomous\_database\_admin\_password output. Provide via tfvars or TF\_VAR; never commit it. | `string` | `null` | no |
| <a name="input_autonomous_database_display_name"></a> [autonomous\_database\_display\_name](#input\_autonomous\_database\_display\_name) | Display name of the Autonomous Database. | `string` | `"free-tier-db"` | no |
| <a name="input_autonomous_database_enabled"></a> [autonomous\_database\_enabled](#input\_autonomous\_database\_enabled) | Create an Always Free Autonomous Database. Disabled by default. | `bool` | `false` | no |
| <a name="input_autonomous_database_workload"></a> [autonomous\_database\_workload](#input\_autonomous\_database\_workload) | Workload type: OLTP (Autonomous Transaction Processing) or DW (Autonomous Data Warehouse). | `string` | `"OLTP"` | no |
| <a name="input_boot_volume_size_in_gbs"></a> [boot\_volume\_size\_in\_gbs](#input\_boot\_volume\_size\_in\_gbs) | Boot volume size in GBs per instance. The Always Free tier includes 200 GB of block storage in total, so num\_instances × boot\_volume\_size\_in\_gbs must stay below 200. | `number` | `100` | no |
| <a name="input_compartment_ocid"></a> [compartment\_ocid](#input\_compartment\_ocid) | Compartment ocid where to create all resources | `string` | n/a | yes |
| <a name="input_fingerprint"></a> [fingerprint](#input\_fingerprint) | Fingerprint of oci api private key. Leave unset to use the OCI CLI configuration file (~/.oci/config). | `string` | `null` | no |
| <a name="input_freeform_tags"></a> [freeform\_tags](#input\_freeform\_tags) | Freeform tags applied to all created resources (merged over the default { ManagedBy = "terraform" }). | `map(string)` | `{}` | no |
| <a name="input_image_os_version"></a> [image\_os\_version](#input\_image\_os\_version) | Operating system version used when selecting the image automatically (e.g. "24.04"). | `string` | `"24.04"` | no |
| <a name="input_ingress_rules"></a> [ingress\_rules](#input\_ingress\_rules) | Inbound security list rules. Default allows SSH from anywhere. protocol accepts tcp, udp, icmp, all (or a protocol number); port applies to tcp/udp. | <pre>list(object({<br/>    protocol    = string<br/>    port        = optional(number)<br/>    source      = string<br/>    description = optional(string)<br/>  }))</pre> | <pre>[<br/>  {<br/>    "port": 22,<br/>    "protocol": "tcp",<br/>    "source": "0.0.0.0/0"<br/>  }<br/>]</pre> | no |
| <a name="input_instance_ad_number"></a> [instance\_ad\_number](#input\_instance\_ad\_number) | Zero-based index of the availability domain to launch the instance in. Wraps around (round-robin) when the region has fewer availability domains. | `number` | `0` | no |
| <a name="input_instance_image_ocid"></a> [instance\_image\_ocid](#input\_instance\_image\_ocid) | Optional per-region image OCID overrides (e.g. { "us-ashburn-1" = "ocid1.image..."). When unset, the latest Canonical Ubuntu image compatible with the shape is selected automatically. | `map(string)` | `{}` | no |
| <a name="input_instance_name"></a> [instance\_name](#input\_instance\_name) | Name of the instance. Used to derive resource display names and DNS labels, so it must be short and alphanumeric. | `string` | n/a | yes |
| <a name="input_instance_ocpus"></a> [instance\_ocpus](#input\_instance\_ocpus) | Number of OCPUs | `number` | `1` | no |
| <a name="input_instance_shape"></a> [instance\_shape](#input\_instance\_shape) | The shape of an instance. | `string` | `"VM.Standard.A1.Flex"` | no |
| <a name="input_instance_shape_config_memory_in_gbs"></a> [instance\_shape\_config\_memory\_in\_gbs](#input\_instance\_shape\_config\_memory\_in\_gbs) | Amount of Memory (GB) | `number` | `6` | no |
| <a name="input_instance_source_type"></a> [instance\_source\_type](#input\_instance\_source\_type) | The source type for the instance. | `string` | `"image"` | no |
| <a name="input_instance_user"></a> [instance\_user](#input\_instance\_user) | Default user on the instance image, used for the auto\_iptables remote-exec connection (ubuntu for Canonical Ubuntu images, opc for Oracle Linux). | `string` | `"ubuntu"` | no |
| <a name="input_num_instances"></a> [num\_instances](#input\_num\_instances) | Number of instances to create. | `number` | `1` | no |
| <a name="input_object_storage_buckets"></a> [object\_storage\_buckets](#input\_object\_storage\_buckets) | Buckets to create when object\_storage\_enabled is true. Bucket names must be unique per tenancy. | <pre>list(object({<br/>    name         = string<br/>    storage_tier = optional(string, "Standard")<br/>    versioning   = optional(string, "Disabled")<br/>  }))</pre> | `[]` | no |
| <a name="input_object_storage_enabled"></a> [object\_storage\_enabled](#input\_object\_storage\_enabled) | Create Object Storage buckets. Disabled by default. | `bool` | `false` | no |
| <a name="input_private_key_path"></a> [private\_key\_path](#input\_private\_key\_path) | Path to oci api private key used. Leave unset to use the OCI CLI configuration file (~/.oci/config). | `string` | `null` | no |
| <a name="input_public_ip"></a> [public\_ip](#input\_public\_ip) | Lifetime of the public IP attached to the primary VNIC. Valid values are NONE, RESERVED or EPHEMERAL. EPHEMERAL addresses change on stop/start; RESERVED ones are free while attached and survive reboots. | `string` | `"NONE"` | no |
| <a name="input_region"></a> [region](#input\_region) | The oci region where resources will be created. Leave unset to use the region from the OCI CLI configuration file (~/.oci/config). | `string` | `null` | no |
| <a name="input_spread_across_ads"></a> [spread\_across\_ads](#input\_spread\_across\_ads) | Distribute instances round-robin across all availability domains instead of pinning them to instance\_ad\_number. Improves odds against Out of Capacity in multi-instance deploys. | `bool` | `false` | no |
| <a name="input_ssh_private_key"></a> [ssh\_private\_key](#input\_ssh\_private\_key) | Private SSH key for remote execution. | `string` | `null` | no |
| <a name="input_ssh_public_keys"></a> [ssh\_public\_keys](#input\_ssh\_public\_keys) | Public SSH keys to be included in the ~/.ssh/authorized\_keys file for the default user on the instance. To provide multiple keys, see docs/instance\_ssh\_keys.adoc. | `string` | `null` | no |
| <a name="input_subnet_cidr_block"></a> [subnet\_cidr\_block](#input\_subnet\_cidr\_block) | The deployment subnet cidr block (e.g., '10.1.20.0/24') | `string` | `"10.1.20.0/24"` | no |
| <a name="input_tenancy_ocid"></a> [tenancy\_ocid](#input\_tenancy\_ocid) | Tenancy ocid where to create the sources. Leave unset to use the OCI CLI configuration file (~/.oci/config). | `string` | `null` | no |
| <a name="input_user_ocid"></a> [user\_ocid](#input\_user\_ocid) | Ocid of user that terraform will use to create the resources. Leave unset to use the OCI CLI configuration file (~/.oci/config). | `string` | `null` | no |
| <a name="input_vcn_cidr_blocks"></a> [vcn\_cidr\_blocks](#input\_vcn\_cidr\_blocks) | The deployment vcn cidr block (e.g., ['10.1.0.0/16', '172.30.0.0/20']) | `list(string)` | <pre>[<br/>  "10.1.0.0/16"<br/>]</pre> | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_autonomous_database_admin_password"></a> [autonomous\_database\_admin\_password](#output\_autonomous\_database\_admin\_password) | ADMIN password for the Autonomous Database (the generated one when autonomous\_database\_admin\_password was unset). |
| <a name="output_autonomous_database_connection_strings"></a> [autonomous\_database\_connection\_strings](#output\_autonomous\_database\_connection\_strings) | Connection strings of the Autonomous Database (null when disabled). |
| <a name="output_autonomous_database_id"></a> [autonomous\_database\_id](#output\_autonomous\_database\_id) | OCID of the Autonomous Database (null when disabled). |
| <a name="output_boot_volume_ids"></a> [boot\_volume\_ids](#output\_boot\_volume\_ids) | OCIDs of the instances' boot volumes. |
| <a name="output_bucket_ids"></a> [bucket\_ids](#output\_bucket\_ids) | OCIDs of the created Object Storage buckets. |
| <a name="output_bucket_names"></a> [bucket\_names](#output\_bucket\_names) | Names of the created Object Storage buckets. |
| <a name="output_instance_devices"></a> [instance\_devices](#output\_instance\_devices) | Block storage devices attached to each instance. |
| <a name="output_instance_ocids"></a> [instance\_ocids](#output\_instance\_ocids) | OCIDs of the instances. |
| <a name="output_instance_private_ips"></a> [instance\_private\_ips](#output\_instance\_private\_ips) | Private IP addresses of the instances. |
| <a name="output_instance_public_ips"></a> [instance\_public\_ips](#output\_instance\_public\_ips) | Public IP addresses of the instances (empty when assign\_public\_ip is false). |
| <a name="output_reserved_public_ips"></a> [reserved\_public\_ips](#output\_reserved\_public\_ips) | Reserved public IP addresses attached to the instances (public\_ip = "RESERVED"). |
| <a name="output_security_list_id"></a> [security\_list\_id](#output\_security\_list\_id) | OCID of the security list controlling the subnet's ingress/egress rules. |
| <a name="output_subnet_id"></a> [subnet\_id](#output\_subnet\_id) | OCID of the subnet created for the deployment. |
| <a name="output_vcn_id"></a> [vcn\_id](#output\_vcn\_id) | OCID of the VCN created for the deployment. |
<!-- END_TF_DOCS -->

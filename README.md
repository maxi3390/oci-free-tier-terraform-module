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

## Free tier limits

The module validates your configuration against the Always Free allowances:

- **Block storage (hard limit)**: 200 GB in total. `num_instances × boot_volume_size_in_gbs` must stay below 200 (e.g. `2 × 99` or `4 × 49`); plans exceeding it fail validation.
- **A1 budget (warnings)**: 4 OCPUs and 24 GB of memory in total across all instances. Exceeding these emits a warning during plan (useful if you also consume the budget outside this module).

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
````

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

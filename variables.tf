variable "fingerprint" {
  description = "Fingerprint of oci api private key"
  type        = string
}

variable "private_key_path" {
  description = "Path to oci api private key used"
  type        = string
}

variable "region" {
  description = "The oci region where resources will be created"
  type        = string
}

variable "tenancy_ocid" {
  description = "Tenancy ocid where to create the sources"
  type        = string
}

variable "user_ocid" {
  description = "Ocid of user that terraform will use to create the resources"
  type        = string
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
  default     = 1
  description = "The availability domain number of the instance. If none is provided, it will start with AD-1 and continue in round-robin."
  type        = number
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

variable "availability_domain" {
  default     = 3
  description = "Availability Domain of the instance"
  type        = number
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
  default     = "200"
  description = "Boot volume size in GBs"
  type        = number
}

variable "instance_image_ocid" {
  type = map(string)

  # See https://docs.us-phoenix-1.oraclecloud.com/images/
  # Canonical-Ubuntu-24.04-Minimal-aarch64-2026.02.28-0
  default = {
    af-johannesburg-1 = "ocid1.image.oc1.af-johannesburg-1.aaaaaaaapfnpqlay4d5nwscq3rruhfdef7iuy3uj6ag42qk5hzoteovjscha"
    ap-chuncheon-1    = "ocid1.image.oc1.ap-chuncheon-1.aaaaaaaarsz6k64njkodoznlllty5rapi2pts4iivamywtjb6tisjnlfw2ra"
    ap-hyderabad-1    = "ocid1.image.oc1.ap-hyderabad-1.aaaaaaaabqvdk4lqx2ct5xyt6p6yk3wahsy4kx26tlnv5itzr7vgicfna4ha"
    ap-melbourne-1    = "ocid1.image.oc1.ap-melbourne-1.aaaaaaaa73fu3p7q7aycwenmf4wtezhmfip5jrjy4t6ejj3otn5rs4wmrisq"
    ap-mumbai-1       = "ocid1.image.oc1.ap-mumbai-1.aaaaaaaa3nqci7foay635jm45ozbt4bfb44bavheamw7rdz4izwuobbnql6a"
    ap-osaka-1        = "ocid1.image.oc1.ap-osaka-1.aaaaaaaamg557mv3wcouedq6ksfcpy6pukm4zm6pv5sfdljizrr55sjsfchq"
    ap-seoul-1        = "ocid1.image.oc1.ap-seoul-1.aaaaaaaae5dqssutnmejddxsq54jjg325skera6l57vgsohths75dem3sp4a"
    ap-singapore-1    = "ocid1.image.oc1.ap-singapore-1.aaaaaaaabllija6kdxl2rz5jbvvmlgvr4fk4pjl5hk2adnau254w43lljxra"
    ap-sydney-1       = "ocid1.image.oc1.ap-sydney-1.aaaaaaaasprcrunw26ssckiqd4oyn7mx6ydtejbmc3ke2arovq6sk3uarsza"
    ap-tokyo-1        = "ocid1.image.oc1.ap-tokyo-1.aaaaaaaaukwmmxwmglidrh2qqv5sjxqdsqnituiovnlwmj7k5ckro63yipgq"
    ca-montreal-1     = "ocid1.image.oc1.ca-montreal-1.aaaaaaaawgmulf554os3qyyj25vweyrbglkbhjmysv2ax4gav7djzmurqtjq"
    ca-toronto-1      = "ocid1.image.oc1.ca-toronto-1.aaaaaaaa6jqvlq72cmky2o5ggc3v5wr2eyuckstlpvxhzvhnmbgpqoz6dl6q"
    eu-amsterdam-1    = "ocid1.image.oc1.eu-amsterdam-1.aaaaaaaaowahxyxzcqaemrliicx42fhvbiicg3qganotlxi5buvirylfderq"
    eu-frankfurt-1    = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaav7j5fmkuvwreezyn7pkyyzgexm4uaobnceclctrmkj2urjvo6e5a"
    eu-madrid-1       = "ocid1.image.oc1.eu-madrid-1.aaaaaaaaqkggomkfjrda56ob37p67ir3puakewkae46x4dp3qdoypmu7ec6a"
    eu-marseille-1    = "ocid1.image.oc1.eu-marseille-1.aaaaaaaaokcyeetmpsur6f3offp2v5ccqw5nuny62x5avmfl3sa4h4icmbaq"
    eu-milan-1        = "ocid1.image.oc1.eu-milan-1.aaaaaaaaemlfjbzxgbzsgodf6rnhlkxljttw6rf7wtppp7zuv32bvvvgxxyq"
    eu-paris-1        = "ocid1.image.oc1.eu-paris-1.aaaaaaaa35iagnloefityaefi53t5ra2hr2odmczhzf6zaxmlrae3avu5kya"
    eu-stockholm-1    = "ocid1.image.oc1.eu-stockholm-1.aaaaaaaa42zsodumucutiaewe76exqd4xyb5hy2uqbxp4sxj2ijqhk66lb5q"
    eu-zurich-1       = "ocid1.image.oc1.eu-zurich-1.aaaaaaaabfiftrg2bz7dixekmpxdkkkt75djngcyawpknisyg4smal6upfxa"
    il-jerusalem-1    = "ocid1.image.oc1.il-jerusalem-1.aaaaaaaa6rffs3jk6tqebrjbzlatcqki6v6nqvruteqcfvyhcbrruhnvou2q"
    me-abudhabi-1     = "ocid1.image.oc1.me-abudhabi-1.aaaaaaaa64dsdv6iu5vccgdd7qkfm7teefaehpnt4p5ll5oph5wku5zllwgq"
    me-dubai-1        = "ocid1.image.oc1.me-dubai-1.aaaaaaaab352mbi4vcyymzs4ccln576k34khc357fk2hlaqx3cuzjclgkoea"
    me-jeddah-1       = "ocid1.image.oc1.me-jeddah-1.aaaaaaaae4ykzuk2hbdnvpwoh24jlsqop4ubcfqrjrnq73dyvkpb27m2hotq"
    mx-monterrey-1    = "ocid1.image.oc1.mx-monterrey-1.aaaaaaaaijm5gclhzkdfi27zbbt4epbwbz7shr6t5bgt2lmmbecqrnhoinma"
    mx-queretaro-1    = "ocid1.image.oc1.mx-queretaro-1.aaaaaaaabk6unoufwiua3rwqimbtok54idi3fcdyaghu7u43irnhh7rozpmq"
    sa-bogota-1       = "ocid1.image.oc1.sa-bogota-1.aaaaaaaay6g4bo4j2qdf53mkr77v2u6l6zlxiultv4roz7yeihplbyjw7swa"
    sa-santiago-1     = "ocid1.image.oc1.sa-santiago-1.aaaaaaaa6dm57wxoa53nbfktpgo63renye75qziqpmmf2wogz6lk4zradkbq"
    sa-saopaulo-1     = "ocid1.image.oc1.sa-saopaulo-1.aaaaaaaaoxzo2yldbwjanbzsfnefwdjyifpp4lb3wvamwbveauvx7kg3gqwq"
    sa-valparaiso-1   = "ocid1.image.oc1.sa-valparaiso-1.aaaaaaaacx5gcbw3z6akzs623dwfnhcq7i5q3k5i6uox2cigo6vqkwqyutqa"
    sa-vinhedo-1      = "ocid1.image.oc1.sa-vinhedo-1.aaaaaaaal7m4osl4hlne3oppz72wlehj6ubeu7kbbandefqcxm54o6ysswra"
    uk-cardiff-1      = "ocid1.image.oc1.uk-cardiff-1.aaaaaaaasxspuw2ps5khuavqs77d4c33gawczeeetjo6zhgonm6s43ifpdqq"
    uk-london-1       = "ocid1.image.oc1.uk-london-1.aaaaaaaaepiqdtffywgr5jd7ypt4rvnddueo4jilw4qb35onsnuowjxc6lfa"
    us-ashburn-1      = "ocid1.image.oc1.iad.aaaaaaaai7jydfj624afgrkqvvykdvvdvskdo6upkhys56nyskim3mr526va"
    us-chicago-1      = "ocid1.image.oc1.us-chicago-1.aaaaaaaahx57wqrsua2bw4oe63vnsvdc7pgx3yllpolzr2psvcq6qwg26yja"
    us-phoenix-1      = "ocid1.image.oc1.phx.aaaaaaaavgzv3uxxskrwd6tmm2jfmkzqx25aq2inzcx7bs5op23ft35qgyfq"
    us-sanjose-1      = "ocid1.image.oc1.us-sanjose-1.aaaaaaaagg6cb3x6qxcoerzncv7zyrhpnwnijp7wuuot6uxrsiiwvzfhaqfq"
  }
}

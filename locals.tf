locals {
  tags = merge({ ManagedBy = "terraform" }, var.freeform_tags)
}

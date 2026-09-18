resource "null_resource" "remote-exec" {
  count = var.auto_iptables ? var.num_instances : 0

  connection {
    agent       = false
    timeout     = "30m"
    host        = element(oci_core_instance.atlas_instance.*.public_ip, count.index)
    user        = "ubuntu"
    private_key = file(var.ssh_private_key)
  }

  provisioner "remote-exec" {
    inline = [
      "export DATE=$(date +%Y%m%d); sudo iptables -L > \"/home/ubuntu/iptables-$DATE.bak\"",
      "sudo sh -c 'iptables -D INPUT -j REJECT --reject-with icmp-host-prohibited 2> /dev/null; iptables-save > /etc/iptables/rules.v4;'",
      "sudo sh -c 'iptables -D FORWARD -j REJECT --reject-with icmp-host-prohibited 2> /dev/null; iptables-save > /etc/iptables/rules.v4;'",
    ]
  }
}
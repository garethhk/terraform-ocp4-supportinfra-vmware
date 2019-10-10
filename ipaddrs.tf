locals {
  node_count = "${var.bastion["nodes"] + var.dns["nodes"]}"
  gateways   = ["${compact(list(var.public_gateway, var.private_gateway))}"]
}

data "template_file" "bastion_private_ips" {
  count    = "${var.bastion["nodes"]}"
  template = "${element(var.bastion_private_ip, count.index)}"
}

data "template_file" "dns_private_ips" {
  count    = "${var.dns["nodes"]}"
  template = "${element(var.dns_private_ip, count.index)}"

}


data "template_file" "public_ips" {
  count    = "${var.public_network_id != "" ? var.bastion["nodes"] : 0}"
  template = "${element(var.bastion_public_ip, count.index)}"
}

data "template_file" "dns_public_ips" {
  count    = "${var.public_network_id != "" ? var.dns["nodes"] : 0}"
  template = "${element(var.dns_public_ip, count.index)}"
}
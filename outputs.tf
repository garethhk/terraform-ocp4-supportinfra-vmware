#################################################
# Output Bastion Node
#################################################

output "bastion_public_ip" {
  value = "${element(compact(concat(vsphere_virtual_machine.bastion.*.default_ip_address, vsphere_virtual_machine.bastion_ds_cluster.*.default_ip_address)), 0)}"
}

# always the first private IP
output "bastion_private_ip" {
  value = "${element(data.template_file.bastion_private_ips.*.rendered, 0)}"
}

output "bastion_hostname" {
  value = "${element(compact(concat(vsphere_virtual_machine.bastion.*.name, vsphere_virtual_machine.bastion_ds_cluster.*.name)), 0)}"
}


#################################################
# Output DNS Node
#################################################

output "dns_private_ip" {
  value = "${list(element(data.template_file.dns_private_ips.*.rendered, 0))}"
}

output "dns_public_ip" {
  value = "${list(element(data.template_file.dns_public_ips.*.rendered, 0))}"
}

output "module_completed" {
  value = "${join(",", concat(
    vsphere_virtual_machine.bastion_ds_cluster.*.id,
    vsphere_virtual_machine.bastion.*.id,
    vsphere_virtual_machine.dns_ds_cluster.*.id,
    vsphere_virtual_machine.dns.*.id
  ))}"
}
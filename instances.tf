#################################
# Configure the VMware vSphere Provider
##################################
provider "vsphere" {
  version        = "~> 1.1"
  vsphere_server = "${var.vsphere_server}"

  # if you have a self-signed cert
  allow_unverified_ssl = "${var.allow_unverified_ssl}"
}

data "vsphere_virtual_machine" "rhel_template" {
  name          = "${var.rhel_template}"
  datacenter_id = "${var.vsphere_datacenter_id}"
}


##################################
#### Create the Bastion VM
##################################
resource "vsphere_virtual_machine" "bastion" {
  #depends_on = ["vsphere_folder.ocpenv"]
  folder = "${var.folder_path}"

  #####
  # VM Specifications
  ####
  count            = "${var.datastore_id != "" ? var.bastion["nodes"] : 0}"
  resource_pool_id = "${var.vsphere_resource_pool_id}"

  name     = "${format("${lower(var.instance_name)}-bastion-%02d", count.index + 1)}"
  num_cpus = "${var.bastion["vcpu"]}"
  memory   = "${var.bastion["memory"]}"

  scsi_controller_count = 1

  ####
  # Disk specifications
  ####
  datastore_id = "${var.datastore_id}"
  guest_id     = "${data.vsphere_virtual_machine.rhel_template.guest_id}"
  scsi_type    = "${data.vsphere_virtual_machine.rhel_template.scsi_type}"

  disk {
    label            = "disk0"
    size             = "${var.bastion["disk_size"] != "" ? var.bastion["disk_size"] : data.vsphere_virtual_machine.rhel_template.disks.0.size}"
    eagerly_scrub    = "${var.bastion["eagerly_scrub"] != "" ? var.bastion["eagerly_scrub"] : data.vsphere_virtual_machine.rhel_template.disks.0.eagerly_scrub}"
    thin_provisioned = "${var.bastion["thin_provisioned"] != "" ? var.bastion["thin_provisioned"] : data.vsphere_virtual_machine.rhel_template.disks.0.thin_provisioned}"
    keep_on_remove   = "${var.bastion["keep_disk_on_remove"]}"
    unit_number      = 0
  }

  disk {
    label            = "disk1"
    size             = "${var.bastion["docker_disk_size"]}"
    eagerly_scrub    = "${var.bastion["eagerly_scrub"] != "" ? var.bastion["eagerly_scrub"] : data.vsphere_virtual_machine.rhel_template.disks.0.eagerly_scrub}"
    thin_provisioned = "${var.bastion["thin_provisioned"] != "" ? var.bastion["thin_provisioned"] : data.vsphere_virtual_machine.rhel_template.disks.0.thin_provisioned}"
    keep_on_remove   = "${var.bastion["keep_disk_on_remove"]}"
    unit_number      = 1
  }


  ####
  # Network specifications
  ####
  dynamic "network_interface" {
    for_each = "${compact(concat(list(var.public_network_id, var.private_network_id)))}"
    content {
      network_id   = "${network_interface.value}"
      adapter_type = "${data.vsphere_virtual_machine.rhel_template.network_interface_types[0]}"
    }
  }

  ####
  # VM Customizations
  ####
  clone {
    template_uuid = "${data.vsphere_virtual_machine.rhel_template.id}"

    customize {
      linux_options {
        host_name = "${var.instance_name}-bastion"
        domain    = "${var.private_domain != "" ? var.private_domain : format("%s.local", var.instance_name)}"
      }

      dynamic "network_interface" {
        for_each = "${compact(concat(list(var.public_network_id, var.private_network_id)))}"
        content {
          ipv4_address = "${element(concat(data.template_file.public_ips.*.rendered, data.template_file.bastion_private_ips.*.rendered), network_interface.key)}"
          ipv4_netmask = "${element(compact(concat(list(var.public_netmask), list(var.private_netmask))), network_interface.key)}"
        }
      }

      # set the default gateway to public if available.  TODO: static routes for private network
      ipv4_gateway = "${var.public_gateway != "" ? var.public_gateway : var.private_gateway}"

      dns_server_list = "${compact(concat(var.private_dns_servers, var.public_dns_servers))}"
      dns_suffix_list = "${compact(list(var.private_domain, var.public_domain))}"
    }
  }

  # Specify the ssh connection
  connection {
    host        = "${self.default_ip_address}"
    user        = "${var.template_ssh_user}"
    password    = "${var.template_ssh_password}"
    private_key = "${var.template_ssh_private_key}"
  }

  provisioner "file" {
    source      = "${path.module}/scripts"
    destination = "/tmp/terraform_scripts"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod u+x /tmp/terraform_scripts/*.sh",
      "/tmp/terraform_scripts/add-private-ssh-key.sh \"${var.ssh_private_key}\" \"${var.ssh_user}\"",
      "/tmp/terraform_scripts/add-public-ssh-key.sh \"${var.ssh_public_key}\""
    ]
  }

}


##################################
#### Create the DNS VM
##################################
resource "vsphere_virtual_machine" "dns" {
  #depends_on = ["vsphere_folder.ocpenv"]
  folder = "${var.folder_path}"

  #####
  # VM Specifications
  ####
  count            = "${var.datastore_id != "" ? var.dns["nodes"] : 0}"
  resource_pool_id = "${var.vsphere_resource_pool_id}"

  name     = "${format("${lower(var.instance_name)}-dns-%02d", count.index + 1)}"
  num_cpus = "${var.dns["vcpu"]}"
  memory   = "${var.dns["memory"]}"

  scsi_controller_count = 1

  ####
  # Disk specifications
  ####
  datastore_id     = "${var.datastore_id}"
  guest_id         = "${data.vsphere_virtual_machine.rhel_template.guest_id}"
  scsi_type        = "${data.vsphere_virtual_machine.rhel_template.scsi_type}"
  enable_disk_uuid = true

  disk {
    label            = "disk0"
    size             = "${var.dns["disk_size"] != "" ? var.dns["disk_size"] : data.vsphere_virtual_machine.rhel_template.disks.0.size}"
    eagerly_scrub    = "${var.dns["eagerly_scrub"] != "" ? var.dns["eagerly_scrub"] : data.vsphere_virtual_machine.rhel_template.disks.0.eagerly_scrub}"
    thin_provisioned = "${var.dns["thin_provisioned"] != "" ? var.dns["thin_provisioned"] : data.vsphere_virtual_machine.rhel_template.disks.0.thin_provisioned}"
    keep_on_remove   = "${var.dns["keep_disk_on_remove"]}"
    unit_number      = 0
  }

  ####
  # Network specifications
  ####
  dynamic "network_interface" {
    for_each = "${compact(concat(list(var.public_network_id, var.private_network_id)))}"
    content {
      network_id   = "${network_interface.value}"
      adapter_type = "${data.vsphere_virtual_machine.rhel_template.network_interface_types[0]}"
    }
  }
  ####
  # VM Customizations
  ####
  clone {
    template_uuid = "${data.vsphere_virtual_machine.rhel_template.id}"

    customize {
      linux_options {
        host_name = "${format("${lower(var.instance_name)}-dns-%02d", count.index + 1)}"
        domain    = "${var.private_domain != "" ? var.private_domain : format("%s.local", var.instance_name)}"
      }

      dynamic "network_interface" {
        for_each = "${compact(concat(list(var.public_network_id, var.private_network_id)))}"
        content {
          ipv4_address = "${element(concat(data.template_file.dns_public_ips.*.rendered, data.template_file.dns_private_ips.*.rendered), network_interface.key)}"
          ipv4_netmask = "${element(compact(concat(list(var.public_netmask), list(var.private_netmask))), network_interface.key)}"
        }
      }

      # set the default gateway to public if available.  TODO: static routes for private network
      ipv4_gateway = "${var.public_gateway != "" ? var.public_gateway : var.private_gateway}"

      dns_server_list = "${var.public_dns_servers}"
      dns_suffix_list = ["${var.private_domain}"]
    }
  }

  # Specify the ssh connection
  connection {
    host        = "${self.default_ip_address}"
    user        = "${var.template_ssh_user}"
    password    = "${var.template_ssh_password}"
    private_key = "${var.template_ssh_private_key}"

    bastion_host        = "${vsphere_virtual_machine.bastion.0.default_ip_address}"
    bastion_user        = "${var.template_ssh_user}"
    bastion_password    = "${var.template_ssh_password}"
    bastion_private_key = "${var.template_ssh_private_key}"
  }

  provisioner "file" {
    source      = "${path.module}/scripts"
    destination = "/tmp/terraform_scripts"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod u+x /tmp/terraform_scripts/*.sh",
      "/tmp/terraform_scripts/add-public-ssh-key.sh \"${var.ssh_public_key}\""
    ]
  }

}

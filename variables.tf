####################################
#### vSphere Access Credentials ####
####################################
variable "vsphere_server" {
  description = "vsphere server to connect to"
}

# Set username/password as environment variables VSPHERE_USER and VSPHERE_PASSWORD
variable "allow_unverified_ssl" {
  description = "Allows terraform vsphere provider to communicate with vsphere servers with self signed certificates"
  default     = "true"
}

##############################################
##### vSphere deployment specifications ######
##############################################
variable "vsphere_datacenter_id" {
  description = "ID of the vsphere datacenter to deploy to"
}

variable "vsphere_cluster_id" {
  description = "ID of vsphere cluster to deploy to"
}

variable "vsphere_resource_pool_id" {
  description = "Path of resource pool to deploy to. i.e. /path/to/pool"
  default     = "/"
}

variable "private_network_id" {
  description = "ID of network to provision VMs on. All node VMs will be provisioned on the same network"
}

variable "public_network_id" {
  description = "ID network to provision the bastion VMs on."
}

variable "datastore_id" {
  description = "Name of datastore to use for the VMs"
  default     = ""
}

variable "datastore_cluster_id" {
  default = ""
}

## Note
# Because of https://github.com/terraform-providers/terraform-provider-vsphere/issues/271 templates must be converted to VMs on ESX 5.5 (and possibly other)
variable "rhel_template" {
  description = "Name of RHEL template or VM to clone for the VM creations. Tested on RHEL 7"
}

variable "folder_path" {
  description = "folder path to place VMs in"
}

variable "cluster_name" {}

variable "instance_name" {
  description = "Name of the ICP installation, will be used as basename for VMs"
}

variable "private_domain" {
  description = "Specify domain of private interface"
}

variable "private_gateway" {
  description = "Default gateway for the newly provisioned VMs. Leave blank to use DHCP"
  default     = ""
}

variable "public_gateway" {
  description = "Default gateway for the newly provisioned VMs. Leave blank to use DHCP"
  default     = ""
}

variable "private_netmask" {
  description = "Netmask in CIDR notation when using static IPs. For example 16 or 24. Set to 0 to retrieve from DHCP"
  default     = 0
}

variable "public_netmask" {
  description = "Netmask in CIDR notation when using static IPs. For example 16 or 24. Set to 0 to retrieve from DHCP"
  default     = 0
}

variable "private_dns_servers" {
  description = "DNS Servers to configure on VMs that are on private network"
  default     = ["8.8.8.8", "8.8.4.4"]
}

variable "public_dns_servers" {
  description = "DNS Servers to configure on VMs that are on public network"
  default     = ["8.8.8.8", "8.8.4.4"]
}

variable "public_domain" {
  description = "domain of public interface"
  default     = ""
}

variable "bastion_ip_address" {
  description = "specify bastion ip addresses individually if they are not contiguous, will override static ip block selection"
  type        = "list"
  default     = []
}

variable "dns_public_ip" {
  description = "specify dns ip addresses individually if they are not contiguous, will override static ip block selection"
  type        = "list"
  default     = []
}

variable "dns_private_ip" {
  description = "specify dns ip addresses individually if they are not contiguous, will override static ip block selection"
  type        = "list"
  default     = []
}

variable "bootstrap_ip_address" {
  description = "specify bootstrap ip address, will override static ip block selection"
  type        = "list"
  default     = []
}

#################################
##### OCP Instance details ######
#################################
variable "bastion" {
  type = "map"

  default = {
    nodes  = "1"
    vcpu   = "2"
    memory = "8192"

    disk_size           = ""      # Specify size or leave empty to use same size as template.
    thin_provisioned    = ""      # True or false. Whether to use thin provisioning on the disk. Leave blank to use same as template
    eagerly_scrub       = ""      # True or false. If set to true disk space is zeroed out on VM creation. Leave blank to use same as template
    keep_disk_on_remove = "false" # Set to 'true' to not delete a disk on removal.
  }
}

variable "dns" {
  type = "map"

  default = {
    nodes  = "1"
    vcpu   = "2"
    memory = "4096"

    disk_size           = ""      # Specify size or leave empty to use same size as template.
    thin_provisioned    = ""      # True or false. Whether to use thin provisioning on the disk. Leave blank to use same as template
    eagerly_scrub       = ""      # True or false. If set to true disk space is zeroed out on VM creation. Leave blank to use same as template
    keep_disk_on_remove = "false" # Set to 'true' to not delete a disk on removal.
  }
}

variable "template_ssh_user" {
  description = "Username which terraform will use to connect to newly created VMs during provisioning"
  default     = "root"
}

variable "template_ssh_password" {
  description = "Password which terraform will use to connect to newly created VMs during provisioning"
  default     = ""
}

variable "template_ssh_private_key" {
  description = "private ssh key contents to connect to newly created VMs during provisioning"
  default     = "/dev/null"
}

variable "ssh_user" {
  description = "Username which terraform add ssh private/public keys to for passwordless ssh"
  default     = "root"
}

variable "ssh_private_key" {
  description = "contents of SSH private key to add to bastion node"
}

variable "ssh_public_key" {
  description = "contents of SSH public key to add to all cluster nodes for passwordless SSH"
}

variable "bastion_public_ip" {
  type    = "list"
  default = []
}

variable "bastion_private_ip" {
  type    = "list"
  default = []
}

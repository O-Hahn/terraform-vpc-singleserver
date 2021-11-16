# Terraform Template to create an IBM Cloud IaaS environment
# Template creates an VPC GEN2
#    ... creating one subnet within one site
#    ... creating one network
#    ... creating a singe instance of a server

variable "zone" {}
variable "vpc" {}
variable "ssh_key" {}
variable "server_name" {}
variable "resource_group_name" {}
variable "data_center" {}

# Get the existing resource goup definition
data "ibm_resource_group" "fhwien_rg" {
  name = var.resource_group_name
}

# Get the image definiton for the base image of the server
data "ibm_is_image" "ds_image" {
  name = "ibm-debian-10-8-minimal-amd64-1"
}

# create a vpc within the resouce group
resource "ibm_is_vpc" "fhwien_vpc" {
  name =  var.vpc
  resource_group = data.ibm_resource_group.fhwien_rg.id
}

# create a subnet within one DC Zone / Location
resource "ibm_is_subnet" "fhwien_subnet" {
  name            = "fh-wien-sn-1"
  vpc             = ibm_is_vpc.fhwien_vpc.id
  zone            = var.zone
  ipv4_cidr_block = "10.243.0.0/18"
  resource_group = data.ibm_resource_group.fhwien_rg.id
}

# create a SSH-Key to be used for the server
resource "ibm_is_ssh_key" "fhwien_sshkey" {
  name       = "ibmsshkey"
  public_key =  var.ssh_key
  resource_group = data.ibm_resource_group.fhwien_rg.id
  }

# create a security-group for network policies
resource "ibm_is_security_group" "fhwien_sg_1" {
    name = "fhwien-sg1"
    vpc  = ibm_is_vpc.fhwien_vpc.id
    resource_group = data.ibm_resource_group.fhwien_rg.id
}

# network rule - allow all incoming network traffic on port 22
resource "ibm_is_security_group_rule" "fhwien_sgr_1_all" {
    group     = ibm_is_security_group.fhwien_sg_1.id
    direction = "inbound"
    remote    = "0.0.0.0/0"

    depends_on = [ibm_is_security_group.fhwien_sg_1]
}

# network rule - allow all incoming network ping 
resource "ibm_is_security_group_rule" "fhwien_sgr_1_icmp" {
    group     = ibm_is_security_group.fhwien_sg_1.id
    direction = "inbound"
    remote    = "0.0.0.0/0"

  icmp {
    type = 8
    #code = 0
  }
    depends_on = [ibm_is_security_group_rule.fhwien_sgr_1_all]
}

# network rule - allow all incoming network traffic on port 22
resource "ibm_is_security_group_rule" "fhwien_sgr_1_ssh" {
    group     = ibm_is_security_group.fhwien_sg_1.id
    direction = "inbound"
    remote    = "0.0.0.0/0"

    tcp {
      port_min = 22
      port_max = 22
    }
    depends_on = [ibm_is_security_group_rule.fhwien_sgr_1_icmp]
}

# create a gateway for all servers into the internet
resource "ibm_is_public_gateway" "fhwien_gateway" {
  name = "fhwien-gateway"
  vpc  = ibm_is_vpc.fhwien_vpc.id
  resource_group = data.ibm_resource_group.fhwien_rg.id
  zone = var.zone

  //User can configure timeouts
  timeouts {
    create = "90m"
  }
}

# create an server instance with 2 nic and attached into the internet 
resource "ibm_is_instance" "fhwien_instance" {
  name    = var.server_name
  image   =  data.ibm_is_image.ds_image.id
  profile = "bx2-2x8"
  resource_group = data.ibm_resource_group.fhwien_rg.id

  primary_network_interface {
    name   = "eth0"
    subnet = ibm_is_subnet.fhwien_subnet.id
    #primary_ipv4_address = "10.243.0.6"
    security_groups = [ibm_is_security_group.fhwien_sg_1.id]
    allow_ip_spoofing = true
  }

  network_interfaces {
    name   = "eth1"
    subnet = ibm_is_subnet.fhwien_subnet.id
    allow_ip_spoofing = false
  }

  vpc  = ibm_is_vpc.fhwien_vpc.id
  zone = var.zone
  keys = [ibm_is_ssh_key.fhwien_sshkey.id]
  depends_on = [ibm_is_security_group_rule.fhwien_sgr_1_ssh]

  //User can configure timeouts
  timeouts {
    create = "15m"
    update = "15m"
    delete = "15m"
  }
}

# create an floating ip adress for the server to be contacted from outside
resource "ibm_is_floating_ip" "fhwien_floatingip" {
  name   = "fhwien-fip1"
  target = ibm_is_instance.fhwien_instance.primary_network_interface[0].id
  resource_group = data.ibm_resource_group.fhwien_rg.id
}

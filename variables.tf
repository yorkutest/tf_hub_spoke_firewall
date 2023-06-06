variable "subscriptionId" {
  type = string
}
variable "location" {
  description = "Location for all resources"
  type        = string
}

variable "computergname" {
  description = "Location for all resources"
  type        = string
}

variable "hub_nsg_rg_name" {
  description = "Name of NSG RG"
  type        = string
}
variable "hub_mgmt_nsg_name" {
  description = "Name of NSG"
  type        = string
}

variable "spoke_web_nsg_name" {
  description = "Name of NSG"
  type        = string
}

variable "vm_admin_user" {
  description = "Username for Virtual Machines"
  type        = string
}
variable "vm_admin_pwd" {
  description = "Password for Virtual Machines"
  type        = string
}

variable "vm_size" {
  description = "Size of the VMs"
  type        = string
}

variable "hub_vm_hostname" {
  description = "Hostname of hub VM "
  type        = string
}
variable "spoke1_vm_hostname" {
  description = "Hostname of spoke1 VM "
  type        = string
}

variable "spoke2_vm_hostname" {
  description = "Hostname of spoke2 VM "
  type        = string
}

variable "hub_vnet_name" {
  description = "Name of Hub vnet"
  type        = string
}
variable "spoke1_vnet_name" {
  description = "Name of spoke 1 "
  type        = string
}

variable "spoke2_vnet_name" {
  description = "Name of spoke 2"
  type        = string
}

variable "hub_mgmt_rules" {
  description = "Open SSH to Hub management network"
  type        = list(map(string))
}

variable "spoke_web_rules" {
  description = "Open SSH to Hub management network"
  type        = list(map(string))
}

variable "rt_table_rg_name" {
  description = "Open SSH to Hub management network"
  type        = string
}
variable "spoke_rt_table_name" {
  description = "Name of custom route table to attach to spoke networks"
  type        = string
}


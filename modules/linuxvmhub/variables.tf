variable "rgname" {
  description = "Resource Group to deploy VM into"
  type        = string
}
variable "location" {
  description = "Resource Group location to deploy to"
  type        = string
}

variable "vmname" {
  description = "Name of the VM"
  type        = string
}
variable "subnetid" {
  description = "ID of the subnet to use for the VM deployment"
  type        = string
}

variable "vmsize" {
  description = "size of VM"
  default     = "Standard_DS2_v2"
  type        = string
}

variable "vmpassword" {
  description = "Password for the VM"
  type        = string
}

variable "adminusername" {
  description = "Name of the admin account"
  type        = string
}

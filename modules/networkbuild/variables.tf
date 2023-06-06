variable "vnet_name" {
  description = "Name of the vnet to create"
  default     = "acctvnet"
  type        = string
}

variable "resource_group_name" {
  description = "Default resource group name that the network will be created in."
  default     = "myapp-rg"
  type        = string
}

variable "location" {
  description = "The location/region where the core network will be created. The full list of Azure regions can be found at https://azure.microsoft.com/regions"
  type        = string
}

variable "address_space" {
  description = "The address space that is used by the virtual network."
  default     = "10.0.0.0/16"
  type        = string
}

# If no values specified, this defaults to Azure DNS 
variable "dns_servers" {
  description = "The DNS servers to be used with vNet."
  default     = []
  type        = list(string)
}

variable "subnet_prefixes" {
  description = "The address prefix to use for the subnet."
  default     = ["10.0.1.0/24"]
  type        = list(string)
}

variable "subnet_names" {
  description = "A list of public subnets inside the vNet."
  default     = ["subnet1"]
  type        = list(string)
}

variable "tags" {
  description = "The tags to associate with your network and subnets."
  type        = map(string)

  default = {
    tag1 = ""
    tag2 = ""
  }
}
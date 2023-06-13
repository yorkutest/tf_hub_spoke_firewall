// general variables 
location       = "canadacentral"
subscriptionId = "ce4ae544-b658-48c0-a894-29f67af78ad7"
// networking variables 
#networkrgname    = "nvalab-network-rg"
hub_vnet_name    = "hubvnet"
spoke1_vnet_name = "spoke1vnet"
spoke2_vnet_name = "spoke2vnet"

// VM variables
computergname      = "nvalab-compute-rg"
hub_vm_hostname    = "hubvm"
spoke1_vm_hostname = "spoke1vmweb"
#spoke2_vm_hostname = "spoke2vmweb"

vm_size       = "Standard_B2s"
vm_admin_user = "vmadmin"
vm_admin_pwd  = "Something!123" // should be adequately complex - uncomment and enter password here for auto reading at runtime

// management nsg related variable entries 

hub_nsg_rg_name    = "nvalab-nsg-rg"
hub_mgmt_nsg_name  = "hub_mgmt_nsg"
spoke_web_nsg_name = "spoke_web_nsg"


hub_mgmt_rules = [
  {
    name                       = "allow-ssh"
    priority                   = "100"
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_ranges         = "*"
    source_address_prefix      = "*"
    destination_port_ranges    = "22"
    destination_address_prefix = "*"
    description                = "Allow SSH to management subnet from any address"
  }
]

spoke_web_rules = [
  {
    name                       = "allow-web"
    priority                   = "100"
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_ranges         = "*"
    source_address_prefix      = "*"
    destination_port_ranges    = "80"
    destination_address_prefix = "*"
    description                = "Allow web 80 to the spoke VMs"
  },
  {
    name                       = "allow-web-https"
    priority                   = "200"
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_ranges         = "*"
    source_address_prefix      = "*"
    destination_port_ranges    = "443"
    destination_address_prefix = "*"
    description                = "Allow web 443 to the spoke VMs"
  }
]

// route table entries

rt_table_rg_name    = "nvalab-udr-rg"
spoke_rt_table_name = "spokeUDRtable"
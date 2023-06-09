# tflint-ignore: terraform_required_providers
resource "random_id" "randomidfirewall" {
  byte_length = 4
}

resource "azurerm_public_ip" "firewall" {
  name                = "firewall_pip"
  location            = var.location
  resource_group_name = module.hubnetwork.vnet_rg_name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "firewallpip-${random_id.randomidfirewall.hex}"
}

resource "azurerm_public_ip" "firewallmgmt" {
  name                = "firewall_mgmt_pip"
  location            = var.location
  resource_group_name = module.hubnetwork.vnet_rg_name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "firewallmgmtpip-${random_id.randomidfirewall.hex}"
}

resource "azurerm_firewall" "hub" {
  name                = "hub_firewall"
  location            = var.location
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  resource_group_name = module.hubnetwork.vnet_rg_name

  ip_configuration {
    name                 = "ipconfig1"
    subnet_id            = module.hubnetwork.vnet_subnets[0]
    public_ip_address_id = azurerm_public_ip.firewall.id
  }

  management_ip_configuration {
    name                 = "mgmtIp"
    subnet_id            = module.hubnetwork.vnet_subnets[1]
    public_ip_address_id = azurerm_public_ip.firewallmgmt.id
  }
  depends_on = [module.hubmanagementvm, module.linuxvmspoke1]
  // The firewall seems to slow down the destroy process for all these objects. approx 66% speed up to allow hub to destroy first using this depends on statement
}

resource "azurerm_firewall_policy" "policy" {
  name                = "BasePolicy"
  resource_group_name = module.hubnetwork.vnet_rg_name
  location            = var.location
  dns {
    proxy_enabled = true
  }
}

resource "azurerm_firewall_policy_rule_collection_group" "example" {
  name               = "fwpolicy-rcg"
  firewall_policy_id = azurerm_firewall_policy.policy.id
  priority           = 100

  network_rule_collection {
    name     = "Allow_ssh_communications_between_spokes"
    priority = 100
    action   = "Allow"
    rule {
      name                  = "spoke1-spoke2"
      source_addresses      = module.spoke1network.subnet_prefixes[0]
      destination_ports     = ["22"]
      destination_addresses = module.spoke2network.subnet_prefixes[0]
      protocols             = ["TCP"]
    }

    rule {
      name                  = "spoke2-spoke1"
      source_addresses      = module.spoke2network.subnet_prefixes[0]
      destination_ports     = ["22"]
      destination_addresses = module.spoke1network.subnet_prefixes[0]
      protocols             = ["TCP"]
    }
  }

  network_rule_collection {
    name     = "Allow_kubernetess_network_communication"
    priority = 300
    action   = "Allow"
    rule {
      name                  = "Port_1194"
      source_addresses      = module.spoke1network.subnet_prefixes[0]
      destination_addresses = ["AzureCloud.canadacentral"]
      destination_ports     = ["1194"]
      protocols             = ["UDP"]
    }

    rule {
      name                  = "Port_9000"
      source_addresses      = module.spoke1network.subnet_prefixes[0]
      destination_addresses = ["AzureCloud.canadacentral"]
      destination_ports     = ["9000"]
      protocols             = ["TCP"]
    }
    rule {
      name              = "NTP"
      source_addresses  = module.spoke1network.subnet_prefixes[0]
      destination_fqdns = ["ntp.ubuntu.com"]
      destination_ports = ["123"]
      protocols         = ["UDP"]
    }
  }

  application_rule_collection {
    name     = "Allow_kubernetess_app_communication"
    priority = 100
    action   = "Allow"
    rule {
      name              = "azmk8s.io"
      source_addresses  = module.spoke1network.subnet_prefixes[0]
      destination_fqdns = ["*.hcp.canadacentral.azmk8s.io", ]
      protocols {
        port = "443"
        type = "Https"
      }
    }

    rule {
      name              = "mcr.microsoft"
      source_addresses  = module.spoke1network.subnet_prefixes[0]
      destination_fqdns = ["mcr.microsoft.com", ]
      protocols {
        port = "443"
        type = "Https"
      }
    }
    rule {
      name              = "data.mcr.microsoft"
      source_addresses  = module.spoke1network.subnet_prefixes[0]
      destination_fqdns = ["*.data.mcr.microsoft.com", ]
      protocols {
        port = "443"
        type = "Https"
      }
    }
    rule {
      name              = "management.azure.com"
      source_addresses  = module.spoke1network.subnet_prefixes[0]
      destination_fqdns = ["management.azure.com", ]
      protocols {
        port = "443"
        type = "Https"
      }
    }
    rule {
      name              = "login.microsoftonline.com"
      source_addresses  = module.spoke1network.subnet_prefixes[0]
      destination_fqdns = ["login.microsoftonline.com", ]
      protocols {
        port = "443"
        type = "Https"
      }
    }
    rule {
      name              = "packages.microsoft.com"
      source_addresses  = module.spoke1network.subnet_prefixes[0]
      destination_fqdns = ["packages.microsoft.com", ]
      protocols {
        port = "443"
        type = "Https"
      }
    }
    rule {
      name              = "acs-mirror.azureedge.net"
      source_addresses  = module.spoke1network.subnet_prefixes[0]
      destination_fqdns = ["acs-mirror.azureedge.net", ]
      protocols {
        port = "443"
        type = "Https"
      }
    }
    rule {
      name              = "ubuntu"
      source_addresses  = module.spoke1network.subnet_prefixes[0]
      destination_fqdns = ["security.ubuntu.com", "azure.archive.ubuntu.com", "changelogs.ubuntu.com"]
      protocols {
        port = "80"
        type = "Http"
      }
    }
  }

}
#resource "azurerm_firewall_network_rule_collection" "rulecollection" {
#  name                = "Allow_ssh_communications_between_spokes"
#  azure_firewall_name = azurerm_firewall.hub.name
#  resource_group_name = module.hubnetwork.vnet_rg_name
#  priority            = 100
#  action              = "Allow"
#
#  rule {
#    name                  = "spoke1-spoke2"
#    source_addresses      = module.spoke1network.subnet_prefixes[0]
#    destination_ports     = ["22"]
#    destination_addresses = module.spoke2network.subnet_prefixes[0]
#    protocols             = ["TCP"]
#  }
#
#  rule {
#    name                  = "spoke2-spoke1"
#    source_addresses      = module.spoke2network.subnet_prefixes[0]
#    destination_ports     = ["22"]
#    destination_addresses = module.spoke1network.subnet_prefixes[0]
#    protocols             = ["TCP"]
#  }
#}

#resource "azurerm_firewall_network_rule_collection" "rulecollection2" {
#  name                = "Allow_kubernetess_communication"
#  azure_firewall_name = azurerm_firewall.hub.name
#  resource_group_name = module.hubnetwork.vnet_rg_name
#  priority            = 300
#  action              = "Allow"
#
#  rule {
#    name                  = "Port_1194"
#    source_addresses      = module.spoke1network.subnet_prefixes[0]
#    destination_addresses = ["AzureCloud.canadacentral"]
#    destination_ports     = ["1194"]
#    protocols             = ["UDP"]
#  }
#
#  rule {
#    name                  = "Port_9000"
#    source_addresses      = module.spoke1network.subnet_prefixes[0]
#    destination_addresses = ["AzureCloud.canadacentral"]
#    destination_ports     = ["9000"]
#    protocols             = ["TCP"]
#  }
#  rule {
#    name              = "NTP"
#    source_addresses  = module.spoke1network.subnet_prefixes[0]
#    destination_fqdns = ["ntp.ubuntu.com"]
#    destination_ports = ["123"]
#    protocols         = ["UDP"]
#  }
#}
#
#
#resource "azurerm_firewall_application_rule_collection" "example" {
#  name                = "Allow_kubernetess_communication"
#  azure_firewall_name = azurerm_firewall.hub.name
#  resource_group_name = module.hubnetwork.vnet_rg_name
#  priority            = 100
#  action              = "Allow"
#
#  rule {
#    name             = "azmk8s.io"
#    source_addresses = module.spoke1network.subnet_prefixes[0]
#    destination_fqdns     = ["*.hcp.canadacentral.azmk8s.io", ]
#    protocols {
#      port = "443"
#      type = "Https"
#    }
#  }
#
#  rule {
#    name             = "mcr.microsoft"
#    source_addresses = module.spoke1network.subnet_prefixes[0]
#    destination_fqdns     = ["mcr.microsoft.com", ]
#    protocols {
#      port = "443"
#      type = "Https"
#    }
#  }
#  rule {
#    name             = "data.mcr.microsoft"
#    source_addresses = module.spoke1network.subnet_prefixes[0]
#    destination_fqdns     = ["*.data.mcr.microsoft.com", ]
#    protocols {
#      port = "443"
#      type = "Https"
#    }
#  }
#  rule {
#    name             = "management.azure.com"
#    source_addresses = module.spoke1network.subnet_prefixes[0]
#    destination_fqdns     = ["management.azure.com", ]
#    protocols {
#      port = "443"
#      type = "Https"
#    }
#  }
#  rule {
#    name             = "login.microsoftonline.com"
#    source_addresses = module.spoke1network.subnet_prefixes[0]
#    destination_fqdns     = ["login.microsoftonline.com", ]
#    protocols {
#      port = "443"
#      type = "Https"
#    }
#  }
#  rule {
#    name             = "packages.microsoft.com"
#    source_addresses = module.spoke1network.subnet_prefixes[0]
#    destination_fqdns     = ["packages.microsoft.com", ]
#    protocols {
#      port = "443"
#      type = "Https"
#    }
#  }
#  rule {
#    name             = "acs-mirror.azureedge.net"
#    source_addresses = module.spoke1network.subnet_prefixes[0]
#    destination_fqdns     = ["acs-mirror.azureedge.net", ]
#    protocols {
#      port = "443"
#      type = "Https"
#    }
#  }
#  rule {
#    name             = "ubuntu"
#    source_addresses = module.spoke1network.subnet_prefixes[0]
#    destination_fqdns     = ["security.ubuntu.com", "azure.archive.ubuntu.com", "changelogs.ubuntu.com"]
#    protocols {
#      port = "80"
#      type = "Http"
#    }
#  }
#}
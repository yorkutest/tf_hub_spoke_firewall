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

  firewall_policy_id = azurerm_firewall_policy.policy.id
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


  nat_rule_collection {
    name     = "nat_rule_collection1"
    priority = 100
    action   = "Dnat"
    rule {
      name                = "nat_rule_collection1_rule1"
      protocols           = ["TCP", "UDP"]
      source_addresses    = ["*"]
      destination_address = azurerm_public_ip.firewall.ip_address
      destination_ports   = ["443"]
      translated_address  = "20.200.116.20"
      translated_port     = "443"
    }
  }
  network_rule_collection {
    name     = "Allow_ssh_communications_between_spokes"
    priority = 250
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

    rule {
      name                  = "DNS"
      source_addresses      = ["*"]
      destination_ports     = ["53"]
      destination_addresses = ["*"]
      protocols             = ["Any"]
    }
  }

  network_rule_collection {
    name     = "Allow_kubernetess_network_communication"
    priority = 300
    action   = "Allow"
    rule {
      name                  = "Port_1194"
      source_addresses      = ["*"]
      destination_addresses = ["AzureCloud.${var.location}"]
      destination_ports     = ["1194"]
      protocols             = ["UDP"]
    }

    rule {
      name                  = "Port_9000"
      source_addresses      = ["*"]
      destination_addresses = ["AzureCloud.${var.location}"]
      destination_ports     = ["9000"]
      protocols             = ["TCP"]
    }
    rule {
      name              = "NTP"
      source_addresses  = ["*"]
      destination_fqdns = ["ntp.ubuntu.com"]
      destination_ports = ["123"]
      protocols         = ["UDP"]
    }
  }


  network_rule_collection {
    name     = "Allow_runner_network_communication"
    priority = 310
    action   = "Allow"
    rule {
      name             = "Runner Urls"
      source_addresses = ["*"]
      destination_fqdns = [
        "github.com",
        "api.github.com",
        "codeload.github.com",
        "actions-results-receiver-production.githubapp.com",
        "objects.githubusercontent.com",
        "objects-origin.githubusercontent.com",
        "github-releases.githubusercontent.com",
        "github-registry-files.githubusercontent.com",
        "ghcr.io"
      ]
      destination_ports = ["443"]
      protocols         = ["TCP"]
    }
  }

  application_rule_collection {
    name     = "Allow_kubernetess_app_communication"
    priority = 350
    action   = "Allow"
    rule {
      name                  = "Kubernetes"
      source_addresses      = ["*"]
      destination_fqdn_tags = ["AzureKubernetesService", ]
      protocols {
        port = "443"
        type = "Https"
      }
      protocols {
        port = "80"
        type = "Http"
      }
    }

    rule {
      name              = "ubuntu"
      source_addresses  = ["*"]
      destination_fqdns = ["security.ubuntu.com", "azure.archive.ubuntu.com", "changelogs.ubuntu.com"]
      protocols {
        port = "80"
        type = "Http"
      }
    }
    rule {
      name              = "mcr"
      source_addresses  = ["*"]
      destination_fqdns = ["mcr.microsoft.com"]
      protocols {
        port = "443"
        type = "Https"
      }
      protocols {
        port = "80"
        type = "Http"
      }
    }

  }

  application_rule_collection {
    name     = "Allow_runner_communication"
    priority = 360
    action   = "Allow"
    rule {
      name              = "Extra Runner Urls"
      source_addresses  = ["*"]
      destination_fqdns = ["quay.io", "*.quay.io"]
      protocols {
        port = "443"
        type = "Https"
      }

    }

    rule {
      name             = "Runner Urls"
      source_addresses = ["*"]
      destination_fqdns = [
        "*.actions.githubusercontent.com",
        "*.blob.core.windows.net",
        "*.actions.githubusercontent.com",
        "*.pkg.github.com"
      ]
      protocols {
        port = "443"
        type = "Https"
      }
    }
    rule {
      name              = "mcr"
      source_addresses  = ["*"]
      destination_fqdns = ["mcr.microsoft.com"]
      protocols {
        port = "443"
        type = "Https"
      }
      protocols {
        port = "80"
        type = "Http"
      }
    }

  }

}

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version =  "4.15.0"
    }
  }
}

provider "azurerm" {
  features {}
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id    
}



resource "azurerm_resource_group" "terra-rg-prod" {
  name     = "terra-rg-prod"
  location = "West US"

}


resource "azurerm_kubernetes_cluster" "terra-aks-prod" {
  name                = "terra-aks-prod"
  location            = "West US"
  resource_group_name = azurerm_resource_group.terra-rg.name
  dns_prefix          = "terra-aks-prod"
  kubernetes_version  = "1.30.6"
  default_node_pool {
    name            = "default"
    node_count      = 1
    vm_size         = "Standard_DS2_v2"
    os_disk_size_gb = 30
    type            = "VirtualMachineScaleSets"
    # availability_zones = [1, 2, 3]
  }

  tags = {
    Environment = "Production"
  }
    service_principal {
        client_id     = var.client_id
        client_secret = var.client_secret
        }
  # network_profile {
  # network_plugin = "azure"
  # dns_service_ip = "
  # service_cidr = "
  # docker_bridge_cidr = "
  # }
}

resource "azurerm_container_group" "terra-acg-prod" {
  name                = "terra-acg-prod"
  location            = azurerm_resource_group.terra-rg.location
  resource_group_name = azurerm_resource_group.terra-rg.name
  os_type             = "Linux"
  container {
    name   = "terra-acg-prod"
    image  = "nginx"
    cpu    = "0.5"
    memory = "1.5"
    ports {
      port     = 80
      protocol = "TCP"
    }
  }
  tags = {
    Environment = "Production"
  }

}

resource "azurerm_container_registry" "terra-acr1982-prod" {
  name                = "terraacr19820203-prod"
  resource_group_name = azurerm_resource_group.terra-rg.name
  location            = azurerm_resource_group.terra-rg.location
  sku                 = "Standard"
  admin_enabled       = true
  tags = {
    Environment = "Production"
  }

}



output "kube_config" {
  value = azurerm_kubernetes_cluster.terra-aks.kube_config_raw
  sensitive = true
}


################################################
# Terraform and Provider
################################################
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.15.0"
    }
  }
}

provider "azurerm" {
  features {}
  client_id       = var.AZURE_CLIENT_ID
  client_secret   = var.AZURE_CLIENT_SECRET
  subscription_id = var.AZURE_SUBSCRIPTION_ID
  tenant_id       = var.AZURE_TENANT_ID
}

################################################
# Resource Group (prod)
################################################
resource "azurerm_resource_group" "terra-rg-prod" {
  name     = "terra-rg-prod"
  location = "West US"

  tags = {
    Environment = "prod"
  }
}

################################################
# AKS Cluster (prod)
################################################
resource "azurerm_kubernetes_cluster" "terra-aks-prod" {
  name                = "terra-aks-prod"
  location            = azurerm_resource_group.terra-rg-prod.location
  resource_group_name = azurerm_resource_group.terra-rg-prod.name
  dns_prefix          = "terra-aks-prod"
  kubernetes_version  = "1.25.6"  # example valid version

  default_node_pool {
    name            = "default"
    node_count      = 1
    vm_size         = "Standard_DS2_v2"
    os_disk_size_gb = 30
    type            = "VirtualMachineScaleSets"
  }

  service_principal {
    client_id     = var.AZURE_CLIENT_ID
    client_secret = var.AZURE_CLIENT_SECRET
  }

  tags = {
    Environment = "prod"
  }
}

################################################
# Azure Container Registry (prod)
################################################
resource "azurerm_container_registry" "terra-acr-prod" {
  name                = "terraacr2025prod" # unique name
  resource_group_name = azurerm_resource_group.terra-rg-prod.name
  location            = azurerm_resource_group.terra-rg-prod.location
  sku                 = "Standard"
  admin_enabled       = true

  tags = {
    Environment = "prod"
  }
}

################################################
# (Optional) Azure Container Instance
################################################
resource "azurerm_container_group" "terra-acg-prod" {
  name                = "terra-acg-prod"
  location            = azurerm_resource_group.terra-rg-prod.location
  resource_group_name = azurerm_resource_group.terra-rg-prod.name
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
    Environment = "prod"
  }
}

################################################
# Output (kube_config)
################################################
output "kube_config_prod" {
  description = "Raw kubeconfig for prod AKS cluster"
  value       = azurerm_kubernetes_cluster.terra-aks-prod.kube_config_raw
  sensitive   = true
}
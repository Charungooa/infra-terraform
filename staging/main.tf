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
# Resource Group (stage)
################################################
resource "azurerm_resource_group" "terra-rg-stage" {
  name     = "terra-rg-stage"
  location = "West US"

  tags = {
    Environment = "stage"
  }
}

################################################
# AKS Cluster (stage)
################################################
resource "azurerm_kubernetes_cluster" "terra-aks-stage" {
  name                = "terra-aks-stage"
  location            = azurerm_resource_group.terra-rg-stage.location
  resource_group_name = azurerm_resource_group.terra-rg-stage.name
  dns_prefix          = "terra-aks-stage"
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
    Environment = "stage"
  }
}

################################################
# Azure Container Registry (stage)
################################################
resource "azurerm_container_registry" "terra-acr-stage" {
  name                = "terraacr2025stage" # unique name
  resource_group_name = azurerm_resource_group.terra-rg-stage.name
  location            = azurerm_resource_group.terra-rg-stage.location
  sku                 = "Standard"
  admin_enabled       = true

  tags = {
    Environment = "stage"
  }
}

################################################
# (Optional) Azure Container Instance
################################################
resource "azurerm_container_group" "terra-acg-stage" {
  name                = "terra-acg-stage"
  location            = azurerm_resource_group.terra-rg-stage.location
  resource_group_name = azurerm_resource_group.terra-rg-stage.name
  os_type             = "Linux"

  container {
    name   = "terra-acg-stage"
    image  = "nginx"
    cpu    = "0.5"
    memory = "1.5"

    ports {
      port     = 80
      protocol = "TCP"
    }
  }

  tags = {
    Environment = "stage"
  }
}

################################################
# Output (kube_config)
################################################
output "kube_config_stage" {
  description = "Raw kubeconfig for stage AKS cluster"
  value       = azurerm_kubernetes_cluster.terra-aks-stage.kube_config_raw
  sensitive   = true
}
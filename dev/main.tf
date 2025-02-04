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


terraform {
  backend "azurerm" {
    storage_account_name = "terraform2025dev"
    container_name       = "terraform-state"
    key                  = "terraform.tfstate"
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
# Resource Group (Dev)
################################################
resource "azurerm_resource_group" "terra-rg-dev" {
  name     = "terra-rg-dev"
  location = "West US"

  tags = {
    Environment = "Dev"
  }
}

################################################
# AKS Cluster (Dev)
################################################
resource "azurerm_kubernetes_cluster" "terra-aks-dev" {
  name                = "terra-aks-dev"
  location            = azurerm_resource_group.terra-rg-dev.location
  resource_group_name = azurerm_resource_group.terra-rg-dev.name
  dns_prefix          = "terra-aks-dev"
  kubernetes_version  = "1.30.6"  # example valid version

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
    Environment = "Dev"
  }
}

################################################
# Azure Container Registry (Dev)
################################################
resource "azurerm_container_registry" "terra-acr-dev" {
  name                = "terraacr2025dev" # unique name
  resource_group_name = azurerm_resource_group.terra-rg-dev.name
  location            = azurerm_resource_group.terra-rg-dev.location
  sku                 = "Standard"
  admin_enabled       = true

  tags = {
    Environment = "Dev"
  }
}

################################################
# (Optional) Azure Container Instance
################################################
resource "azurerm_container_group" "terra-acg-dev" {
  name                = "terra-acg-dev"
  location            = azurerm_resource_group.terra-rg-dev.location
  resource_group_name = azurerm_resource_group.terra-rg-dev.name
  os_type             = "Linux"

  container {
    name   = "terra-acg-dev"
    image  = "nginx"
    cpu    = "0.5"
    memory = "1.5"

    ports {
      port     = 80
      protocol = "TCP"
    }
  }

  tags = {
    Environment = "Dev"
  }
}

################################################
# Output (kube_config)
################################################
output "kube_config_dev" {
  description = "Raw kubeconfig for dev AKS cluster"
  value       = azurerm_kubernetes_cluster.terra-aks-dev.kube_config_raw
  sensitive   = true
}
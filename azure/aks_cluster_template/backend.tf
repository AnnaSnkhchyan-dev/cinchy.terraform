provider "azurerm" {
  partner_id = "<<partner_id>>"
  features {}
}

# Configure the azurerm provider source and version requirements
terraform {
  required_providers {
    azurerm = {
      version = "~>2.92"
    }
  }
}


terraform {
  backend "azurerm" {
    resource_group_name  = "<<terraform_backend_resource_group_name>>"
    storage_account_name = "<<terraform_backend_storage_account_name>>"
    container_name       = "<<terraform_backend_storage_container_name>>"
    key                  = "<<terraform_backend_storage_key>>"
  }
}
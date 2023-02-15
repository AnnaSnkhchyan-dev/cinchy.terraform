#######################################################################
# Resource Module
#######################################################################
resource "azurerm_resource_group" "resource_group" {
  name     = "<<deployment_resource_group>>"
  location = "<<location>>"
}

#######################################################################
# Network Module
#######################################################################
module "network" {
  source              = "../../terraform_modules/network"
  vnet_name           = "<<virtual_network_name>>"
  resource_group_name = azurerm_resource_group.resource_group.name
  address_space       = "<<address_space>>"
  subnet_prefixes     = [ "<<subnet_prefix>>" ]
  subnet_names        = [ "<<subnet_name>>" ]
  depends_on          = [azurerm_resource_group.resource_group]
}

#######################################################################
# AKS Module
#######################################################################
module "aks" {
  source                           = "../../terraform_modules/aks"
  resource_group_name              = azurerm_resource_group.resource_group.name
  kubernetes_version               = "<<kubernetes_version>>"
  orchestrator_version             = "<<orchestrator_version>>"
  prefix                           = "<<cluster_name>>"
  cluster_name                     = "<<cluster_name>>"
  network_plugin                   = "azure"
  network_policy                   = "azure"
  net_profile_service_cidr         = "<<net_profile_service_cidr>>" # Should not overlap with network address_space
  net_profile_dns_service_ip       = "<<net_profile_dns_service_ip>>"   # Should not overlap with network address_space
  net_profile_docker_bridge_cidr   = "172.17.0.0/16"
  vnet_subnet_id                   = module.network.vnet_subnets[0]
  os_disk_size_gb                  = <<os_disk_size_gb>>
  sku_tier                         = "Paid" # defaults to Free
  enable_role_based_access_control = true
  rbac_aad_managed                 = true
  private_cluster_enabled          = <<private_cluster_enabled>> # default value
  enable_azure_policy              = true
  enable_auto_scaling              = true
#  enable_host_encryption           = false
  vm_size                      = "<<vm_size>>" #Standard_D8s_v3
  min_count                 = <<min_count>> #3
  max_count                 = <<max_count>> #6
  node_count                     = null # Please set `node_count` `null` while `enable_auto_scaling` is `true` to avoid possible `node_count` changes.
  node_pool_name                 = "zone1"
  node_availability_zones        = ["1"]
  node_type                      = "VirtualMachineScaleSets"
  private_dns_name               = "<<private_dns_name>>"

  node_labels = {
    "nodepool" : "defaultnodepool"
  }

  node_tags = {
    "node" : "defaultnodepoolagent"
  }

  depends_on = [module.network]
}

module "aks-node-pool" {
  source                = "../../terraform_modules/aks-node-pool"
  resource_group_name   = azurerm_resource_group.resource_group.name
  orchestrator_version  = "<<orchestrator_version>>"
  location              = azurerm_resource_group.resource_group.location
  vnet_subnet_id        = module.network.vnet_subnets[0]
  kubernetes_cluster_id = module.aks.aks_id
  node_pools = {
    zone2 = {
      vm_size                  = "<<vm_size>>"
      enable_auto_scaling      = true
      os_disk_size_gb          = <<os_disk_size_gb>>
      node_count               = null # Please set `node_count` `null` while `enable_auto_scaling` is `true` to avoid possible `node_count` changes.
      min_count                = <<min_count>>
      max_count                = <<max_count>>
      availability_zones       = ["2"]
      enable_host_encryption   = false
    },
    zone3 = {
      vm_size                  = "<<vm_size>>"
      enable_auto_scaling      = true
      os_disk_size_gb          = <<os_disk_size_gb>>
      node_count               = null # Please set `node_count` `null` while `enable_auto_scaling` is `true` to avoid possible `node_count` changes.
      min_count                = <<min_count>>
      max_count                = <<max_count>>
      availability_zones       = ["3"]
      enable_host_encryption   = false
    },
  }
}
#######################################################################
# Blob Storage Module
#######################################################################
resource "azurerm_storage_account" "account" {
  name                     = "<<storage_account_name>>"
  resource_group_name      = azurerm_resource_group.resource_group.name
  location                 = azurerm_resource_group.resource_group.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "connections_storage_container" {
  name                  = "<<connections_storage_container_name>>"
  storage_account_name  = azurerm_storage_account.account.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "web_storage_container" {
  name                  = "<<web_storage_container_name>>"
  storage_account_name  = azurerm_storage_account.account.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "platform_storage_container" {
  name                  = "<<platform_storage_container_name>>"
  storage_account_name  = azurerm_storage_account.account.name
  container_access_type = "private"
}

#######################################################################
# MSSQL Module
#######################################################################
# data "azurerm_log_analytics_workspace" "workspace" {
#   name                = "cinchy-workspace"
#   resource_group_name = azurerm_resource_group.resource_group.name
# }

module "mssql" {
  source = "../../terraform_modules/mssql"

  create_resource_group = false
  resource_group_name   = azurerm_resource_group.resource_group.name
  location              = "<<location>>"

  # SQL Server and Database details
  # Database edition: Hyperscale
  # The valid service objective name for the database include HS_Gen5_2, HS_DC_2, HS_Gen5_4, HS_DC_4, HS_Gen5_6, HS_DC_6, HS_Gen5_8, HS_DC_8, HS_Gen5_10, HS_Gen5_12, HS_Gen5_14, HS_Gen5_16, HS_Gen5_18, HS_Gen5_20, HS_Gen5_24, HS_Gen5_32, HS_Gen5_40, HS_Gen5_80
  sqlserver_name               = "<<sqlserver_name>>"
  database_name                = "<<database_name>>"
  sql_database_edition         = "<<sql_database_edition>>"
  sqldb_service_objective_name = "<<sqldb_service_objective_name>>"

  enable_threat_detection_policy = true
  log_retention_days             = 30

  # (Optional) To enable Azure Monitoring for Azure SQL database including audit logs
  # Log Analytic workspace resource id required
  # (Optional) Specify `storage_account_id` to save monitoring logs to storage. 
  # enable_log_monitoring      = false
  # log_analytics_workspace_id = data.azurerm_log_analytics_workspace.workspace.id
  depends_on          = [azurerm_resource_group.resource_group]
  # Firewall Rules to allow azure and external clients and specific Ip address/ranges. 
  enable_firewall_rules = true
  firewall_rules = <<firewall_rules>>
  # firewall_rules = [
  #   {
  #     name             = "access-to-azure"
  #     start_ip_address = "0.0.0.0"
  #     end_ip_address   = "0.0.0.0"
  #   },
  #   {
  #     name             = "desktop-ip"
  #     start_ip_address = "49.24.25.49"
  #     end_ip_address   = "49.24.25.49"
  #   }
  # ]
}

output "sql_server_admin_password" {
  description = "SQL database administrator login password"
  value       = module.mssql.sql_server_admin_password
  sensitive   = true
}

output "sql_server_admin_user" {
  description = "SQL database administrator login id"
  value       = module.mssql.sql_server_admin_user
  sensitive   = false
}

output "primary_sql_server_fqdn" {
  description = "The fully qualified domain name of the primary Azure SQL Server"
  value       = module.mssql.primary_sql_server_fqdn
}

output "blob_storage_connection_string" {
  description = "Blob Storage connection string"
  value       = azurerm_storage_account.account.primary_blob_connection_string
  sensitive   = true
}
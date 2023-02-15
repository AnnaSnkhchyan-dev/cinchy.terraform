data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

module "ssh-key" {
  source         = "./modules/ssh-key"
  public_ssh_key = var.public_ssh_key == "" ? "" : var.public_ssh_key
}

resource "azurerm_kubernetes_cluster" "main" {
  name                    = var.cluster_name
  kubernetes_version      = var.kubernetes_version
  location                = data.azurerm_resource_group.main.location
  resource_group_name     = data.azurerm_resource_group.main.name
  node_resource_group     = var.node_resource_group
  dns_prefix              = var.prefix
  sku_tier                = var.sku_tier
  private_cluster_enabled = var.private_cluster_enabled

  depends_on = [
    azurerm_role_assignment.role_assignment,
  ]

  linux_profile {
    admin_username = var.admin_username

    ssh_key {
      # remove any new lines using the replace interpolation function
      key_data = replace(var.public_ssh_key == "" ? module.ssh-key.public_ssh_key : var.public_ssh_key, "\n", "")
    }
  }

  dynamic "default_node_pool" {
    for_each = var.enable_auto_scaling == true ? [] : ["default_node_pool_manually_scaled"]
    content {
      orchestrator_version   = var.orchestrator_version
      name                   = var.node_pool_name
      node_count             = var.node_count
      vm_size                = var.vm_size
      os_disk_size_gb        = var.os_disk_size_gb
      vnet_subnet_id         = var.vnet_subnet_id
      enable_auto_scaling    = var.enable_auto_scaling
      max_count              = null
      min_count              = null
      enable_node_public_ip  = var.enable_node_public_ip
      availability_zones     = var.node_availability_zones
      node_labels            = var.node_labels
      type                   = var.node_type
      tags                   = merge(var.tags, var.node_tags)
      max_pods               = var.node_max_pods
      enable_host_encryption = var.enable_host_encryption
      linux_os_config {
      sysctl_config {
        vm_max_map_count = 262144
      }
     }
    }
  }

  dynamic "default_node_pool" {
    for_each = var.enable_auto_scaling == true ? ["default_node_pool_auto_scaled"] : []
    content {
      orchestrator_version   = var.orchestrator_version
      name                   = var.node_pool_name
      vm_size                = var.vm_size
      os_disk_size_gb        = var.os_disk_size_gb
      vnet_subnet_id         = var.vnet_subnet_id
      enable_auto_scaling    = var.enable_auto_scaling
      max_count              = var.max_count
      min_count              = var.min_count
      enable_node_public_ip  = var.enable_node_public_ip
      availability_zones     = var.node_availability_zones
      node_labels            = var.node_labels
      type                   = var.node_type
      tags                   = merge(var.tags, var.node_tags)
      max_pods               = var.node_max_pods
      enable_host_encryption = var.enable_host_encryption
      linux_os_config {
      sysctl_config {
        vm_max_map_count = 262144
      }
     }
    }
  }

  dynamic "service_principal" {
    for_each = var.client_id != "" && var.client_secret != "" ? ["service_principal"] : []
    content {
      client_id     = var.client_id
      client_secret = var.client_secret
    }
  }

  dynamic "identity" {
    for_each = var.client_id == "" || var.client_secret == "" ? ["identity"] : []
    content {
      type                      = var.identity_type
      user_assigned_identity_id = var.user_assigned_identity_id
    }
  }

  addon_profile {
    http_application_routing {
      enabled = var.enable_http_application_routing
    }

    kube_dashboard {
      enabled = var.enable_kube_dashboard
    }

    azure_policy {
      enabled = var.enable_azure_policy
    }

    oms_agent {
      enabled                    = var.enable_log_analytics_workspace
      log_analytics_workspace_id = var.enable_log_analytics_workspace ? azurerm_log_analytics_workspace.main[0].id : null
    }

    dynamic "ingress_application_gateway" {
      for_each = var.enable_ingress_application_gateway == null ? [] : ["ingress_application_gateway"]
      content {
        enabled      = var.enable_ingress_application_gateway
        gateway_id   = var.ingress_application_gateway_id
        gateway_name = var.ingress_application_gateway_name
        subnet_cidr  = var.ingress_application_gateway_subnet_cidr
        subnet_id    = var.ingress_application_gateway_subnet_id
      }
    }
  }

  role_based_access_control {
    enabled = var.enable_role_based_access_control

    dynamic "azure_active_directory" {
      for_each = var.enable_role_based_access_control && var.rbac_aad_managed ? ["rbac"] : []
      content {
        managed                = true
        admin_group_object_ids = var.rbac_aad_admin_group_object_ids
      }
    }

    dynamic "azure_active_directory" {
      for_each = var.enable_role_based_access_control && !var.rbac_aad_managed ? ["rbac"] : []
      content {
        managed           = false
        client_app_id     = var.rbac_aad_client_app_id
        server_app_id     = var.rbac_aad_server_app_id
        server_app_secret = var.rbac_aad_server_app_secret
      }
    }
  }

  network_profile {
    network_plugin     = var.network_plugin
    network_policy     = var.network_policy
    dns_service_ip     = var.net_profile_dns_service_ip
    docker_bridge_cidr = var.net_profile_docker_bridge_cidr
    outbound_type      = var.net_profile_outbound_type
    pod_cidr           = var.net_profile_pod_cidr
    service_cidr       = var.net_profile_service_cidr
  }

  tags = var.tags
}


resource "azurerm_log_analytics_workspace" "main" {
  count               = var.enable_log_analytics_workspace ? 1 : 0
  name                = var.cluster_log_analytics_workspace_name == null ? "${var.prefix}-workspace" : var.cluster_log_analytics_workspace_name
  location            = data.azurerm_resource_group.main.location
  resource_group_name = var.resource_group_name
  sku                 = var.log_analytics_workspace_sku
  retention_in_days   = var.log_retention_in_days

  tags = var.tags
}

resource "azurerm_log_analytics_solution" "main" {
  count                 = var.enable_log_analytics_workspace ? 1 : 0
  solution_name         = "ContainerInsights"
  location              = data.azurerm_resource_group.main.location
  resource_group_name   = var.resource_group_name
  workspace_resource_id = azurerm_log_analytics_workspace.main[0].id
  workspace_name        = azurerm_log_analytics_workspace.main[0].name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }

  tags = var.tags
}


resource "azurerm_private_dns_zone" "private_dns_zone" {
  count               = var.private_cluster_enabled == true ? 1 : 0
  name                = var.private_dns_name
  resource_group_name = data.azurerm_resource_group.main.name
}

resource "azurerm_user_assigned_identity" "user_assigned_identity" {
  count               = var.private_cluster_enabled == true ? 1 : 0
  name                = "aks-${var.cluster_name}-identity"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
}

resource "azurerm_role_assignment" "role_assignment" {
  count                = var.private_cluster_enabled == true ? 1 : 0
  scope                = azurerm_private_dns_zone.private_dns_zone[0].id
  role_definition_name = "Private DNS Zone Contributor"
  principal_id         = azurerm_user_assigned_identity.user_assigned_identity[0].principal_id
}

# This allows Kubernetes service to get IP address from private subnets.
resource "azurerm_role_assignment" "aks_network_rg" {
  scope                 = data.azurerm_resource_group.main.id
  role_definition_name  = "Network Contributor"
  principal_id          = azurerm_kubernetes_cluster.main.identity[0].principal_id
}

resource "azurerm_role_assignment" "aks_network_contributor" {
  scope                 = azurerm_kubernetes_cluster.main.id
  role_definition_name  = "Network Contributor"
  principal_id          = azurerm_kubernetes_cluster.main.identity[0].principal_id
}

resource "azurerm_role_assignment" "aks_network_reader" {
  scope                 = var.vnet_subnet_id
  role_definition_name  = "Reader"
  principal_id          = azurerm_kubernetes_cluster.main.identity[0].principal_id
}

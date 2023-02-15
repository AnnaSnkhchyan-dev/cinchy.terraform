resource "azurerm_kubernetes_cluster_node_pool" "node_pool" {
  for_each                 = try(var.node_pools, {})
  name                     = each.key
  mode                     = try(each.value.mode, "User")
  kubernetes_cluster_id    = var.kubernetes_cluster_id
  orchestrator_version     = var.orchestrator_version
  vm_size                  = try(each.value.vm_size, null)
  os_disk_size_gb          = try(each.value.os_disk_size_gb, null)
  os_disk_type             = try(each.value.os_disk_type, null)
  node_count               = try(each.value.node_count, 1)
  min_count                = try(each.value.min_count, null)
  max_count                = try(each.value.max_count, null)
  priority                 = try(each.value.priority, null)
  eviction_policy          = try(each.value.eviction_policy, null)
  vnet_subnet_id           = var.vnet_subnet_id
  availability_zones       = try(each.value.availability_zones, null)
  enable_auto_scaling      = try(each.value.enable_auto_scaling, false)
  enable_node_public_ip    = try(each.value.enable_node_public_ip, false)
  node_public_ip_prefix_id = try(each.value.node_public_ip_prefix_id, null)
  node_labels              = try(each.value.node_labels, null)
  node_taints              = try(each.value.node_taints, null)
  enable_host_encryption   = try(each.value.enable_host_encryption, false)
  max_pods                 = try(each.value.max_pods, 250)
  linux_os_config {
      sysctl_config {
        vm_max_map_count = 262144
      }
  }


  # tags = merge(var.tags, each.value.agents_tags)
}
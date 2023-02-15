resource "random_password" "this" {
  # Generate a random password if the administrator_password is not set
  count  = var.administrator_password != null ? 0 : 1
  length = 64
}

resource "azurerm_postgresql_flexible_server" "server" {
  count    = var.public_network_access_enabled == true ? 1 : 0 # conditional creation
  name                   = var.server_name
  resource_group_name    = var.resource_group_name
  location               = var.location
  version                = var.server_version
  administrator_login    = var.administrator_login
  administrator_password = var.administrator_password != null ? var.administrator_password : random_password.this[0].result
  storage_mb             = var.storage_mb
  sku_name               = var.sku_name
  zone                   = var.zone
  delegated_subnet_id    = azurerm_subnet.db_subnet.id
  # private_dns_zone_id    = azurerm_private_dns_zone.dns_zone.id
  high_availability {
      mode = "ZoneRedundant"
      standby_availability_zone = var.standby_zone
  }
}

resource "azurerm_postgresql_flexible_server_database" "server" {
  count               = var.public_network_access_enabled == true ? 1 : 0 # conditional creation
  name                = var.db_names
  #server_id =   "${element(concat(azurerm_postgresql_flexible_server.server.id, list("")), 0)}"
  server_id = azurerm_postgresql_flexible_server.server[0].id
  collation = var.db_collation
  charset   = var.db_charset
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "firewall_rules" {
  count            = var.public_network_access_enabled == true ? 1 : 0 # conditional creation
  name             = "default"
  server_id        = azurerm_postgresql_flexible_server.server[0].id
  start_ip_address = var.start_ip_address
  end_ip_address   = var.end_ip_address
}


# resource "azurerm_private_dns_zone" "private_dns_zone" {
#   count    = var.public_network_access_enabled == false ? 1 : 0 # conditional creation
#   name                = "postgresql-zone.postgres.database.azure.com"
#   resource_group_name = var.resource_group_name
# }

# resource "azurerm_private_dns_zone_virtual_network_link" "private_dns_zone_vnet_link" {
#   count    = var.public_network_access_enabled == false ? 1 : 0 # conditional creation
#   name                  = "postgresql-link"
#   private_dns_zone_name = "postgresql-zone.postgres.database.azure.com"
#   virtual_network_id    = var.virtual_network_id
#   resource_group_name   = var.resource_group_name
# }


resource "azurerm_subnet" "db_subnet" {
  name                 = var.subnet_names
  resource_group_name  = var.resource_group_name
  address_prefixes     = var.subnet_prefixes
  service_endpoints    = ["Microsoft.Storage"]
  virtual_network_name = var.virtual_network_name
  delegation {
    name = "fs"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

#### Private Postgresql flexiable server creation
resource "azurerm_postgresql_flexible_server" "private_server" {
  count    = var.public_network_access_enabled == false ? 1 : 0 # conditional creation
  name                   = var.server_name
  resource_group_name    = var.resource_group_name
  location               = var.location
  version                = var.server_version
  administrator_login    = var.administrator_login
  administrator_password = var.administrator_password != null ? var.administrator_password : random_password.this[0].result
  storage_mb             = var.storage_mb
  sku_name               = var.sku_name
  zone                   = var.zone
  delegated_subnet_id    = azurerm_subnet.db_subnet.id
  private_dns_zone_id    = azurerm_private_dns_zone.dns_zone[0].id
  high_availability {
      mode = "ZoneRedundant"
      standby_availability_zone = var.standby_zone
  }
}

resource "azurerm_postgresql_flexible_server_database" "private_server" {
  count               = var.public_network_access_enabled == false ? 1 : 0 # conditional creation
  name                = var.db_names
  #server_id =   "${element(concat(azurerm_postgresql_flexible_server.server.id, list("")), 0)}"
  server_id = azurerm_postgresql_flexible_server.private_server[0].id
  collation = var.db_collation
  charset   = var.db_charset
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "private_firewall_rules" {
  count            = var.public_network_access_enabled == false ? 1 : 0 # conditional creation
  name             = "default"
  server_id        = azurerm_postgresql_flexible_server.private_server[0].id
  start_ip_address = var.start_ip_address
  end_ip_address   = var.end_ip_address
}

resource "azurerm_private_dns_zone" "dns_zone" {
  count    = var.public_network_access_enabled == false ? 1 : 0 # conditional creation
  name                = var.private_dns_zone_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "private_link" {
  count    = var.public_network_access_enabled == false ? 1 : 0 # conditional creation
  name                  = var.server_name
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = var.private_dns_zone_name
  virtual_network_id    = var.virtual_network_id
}


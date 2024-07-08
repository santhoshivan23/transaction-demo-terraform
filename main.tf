# Configure the Azure provider
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.2"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location_eastus
}

resource "azurerm_virtual_network" "vn" {
  name                = var.vnet_name
  location            = var.location_eastus
  resource_group_name = var.resource_group_name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "sn_pvt_ep" {
  name                 = var.subnet_name_pvt_endpoint
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vn.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "sn_aci" {
  name                 = var.subnet_name_aci
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vn.name
  address_prefixes     = ["10.0.2.0/24"]

  delegation {
    name = "delegation"
    service_delegation {
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      name    = "Microsoft.ContainerInstance/containerGroups"
    }
  }

  service_endpoints = ["Microsoft.KeyVault", "Microsoft.Storage"]
}

resource "azurerm_subnet" "sn_vm" {
  name                 = var.subnet_name_vm
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vn.name
  address_prefixes     = ["10.0.3.0/24"]
}

resource "azurerm_storage_account" "storage_acc" {
  name                     = var.storage_acc_name
  resource_group_name      = var.resource_group_name
  location                 = var.location_eastus
  account_tier             = var.account_tier_standard
  account_replication_type = "LRS"
}

resource "azurerm_private_endpoint" "pep" {
  name                = var.private_ep_name_storage
  location            = var.location_eastus
  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.sn_pvt_ep.id

  private_service_connection {
    name                           = var.ep_conn_name
    private_connection_resource_id = azurerm_storage_account.storage_acc.id
    is_manual_connection           = false
    subresource_names              = ["File"]
  }
}

resource "azurerm_storage_share" "acipersshare" {
  name                 = var.aci_pers_share_name
  storage_account_name = azurerm_storage_account.storage_acc.name
  quota                = 50
}

resource "azurerm_storage_share" "mongoshare" {
  name                 = var.aci_mongo_share_name
  storage_account_name = azurerm_storage_account.storage_acc.name
  quota                = 50
}

data "azurerm_key_vault" "kv1" {
  name                = var.keyvault1_name
  resource_group_name = var.resource_group_name
}

data "azurerm_key_vault" "kv2" {
  name                = var.keyvault2_name
  resource_group_name = var.resource_group_name
}

resource "azurerm_role_assignment" "assgkv1" {
  principal_id         = var.admin_principal_id
  role_definition_name = var.keyvault_admin_role
  scope                = data.azurerm_key_vault.kv1.id
}

resource "azurerm_role_assignment" "assgkv2" {
  principal_id         = var.admin_principal_id
  role_definition_name = var.keyvault_admin_role
  scope                = data.azurerm_key_vault.kv2.id
}

resource "azurerm_user_assigned_identity" "ms1identity" {
  location            = azurerm_resource_group.rg.location
  name                = var.ms1identityname
  resource_group_name = var.resource_group_name
}

resource "azurerm_role_assignment" "assgkv1User" {
  principal_id         = azurerm_user_assigned_identity.ms1identity.principal_id
  role_definition_name = var.keyvault_user_role
  scope                = data.azurerm_key_vault.kv1.id
}

resource "azurerm_user_assigned_identity" "ms2identity" {
  location            = azurerm_resource_group.rg.location
  name                = var.ms2identityname
  resource_group_name = var.resource_group_name
}

resource "azurerm_role_assignment" "assgkv2User" {
  principal_id         = azurerm_user_assigned_identity.ms2identity.principal_id
  role_definition_name = var.keyvault_user_role
  scope                = data.azurerm_key_vault.kv2.id
}

resource "azurerm_user_assigned_identity" "mongocosmosidentity" {
  location            = azurerm_resource_group.rg.location
  name                = var.mongodbidentityname
  resource_group_name = var.resource_group_name
}

resource "azurerm_eventhub_namespace" "eventhubns" {
  name                = var.ehnsname
  location            = azurerm_resource_group.rg.location
  resource_group_name = var.resource_group_name
  sku                 = var.account_tier_standard
}

resource "azurerm_eventhub" "eh" {
  name                = var.ehname
  namespace_name      = azurerm_eventhub_namespace.eventhubns.name
  resource_group_name = var.resource_group_name
  partition_count     = 1
  message_retention   = 1
}


resource "azurerm_cosmosdb_account" "mongocosmosdb" {
  name                = var.cosmosdbaccname
  location            = "westus"
  resource_group_name = var.resource_group_name
  offer_type          = var.account_tier_standard
  kind                = "MongoDB"

  capabilities {
    name = "EnableMongo"
  }
  consistency_policy {
    consistency_level = "Eventual"
  }
  geo_location {
    location          = "westus"
    failover_priority = 0
  }
  enable_free_tier     = true
  mongo_server_version = "4.0"
}

resource "azurerm_private_endpoint" "cosmospep" {
  name                = var.private_ep_name_cosmos
  location            = azurerm_resource_group.rg.location
  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.sn_pvt_ep.id

  private_service_connection {
    name                           = "acccosmosdb-Connection"
    private_connection_resource_id = azurerm_cosmosdb_account.mongocosmosdb.id
    is_manual_connection           = false
    subresource_names              = ["MongoDB"]
  }
}

resource "azurerm_redis_cache" "rediscache" {
  name                          = var.rediscachename
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = var.resource_group_name
  capacity                      = 0
  family                        = "C"
  sku_name                      = "Basic"
  public_network_access_enabled = "false"
}

resource "azurerm_private_endpoint" "redispep" {
  name                = var.private_ep_name_redis
  location            = azurerm_resource_group.rg.location
  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.sn_pvt_ep.id

  private_service_connection {
    name                           = "rediscachetrdemo-Connection"
    private_connection_resource_id = azurerm_redis_cache.rediscache.id
    is_manual_connection           = false
    subresource_names              = ["redisCache"]
  }
}

resource "azurerm_network_profile" "subnetprofile" {
  name                = "acisubnetprofile"
  location            = azurerm_resource_group.rg.location
  resource_group_name = var.resource_group_name

  container_network_interface {
    name = "examplecnic"
    ip_configuration {
      name      = "aziipconfig"
      subnet_id = azurerm_subnet.sn_aci.id
    }
  }
}

resource "azurerm_container_group" "mongocontainer" {
  resource_group_name = var.resource_group_name
  name                = var.containergroupname
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  network_profile_id  = azurerm_network_profile.subnetprofile.id
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.mongocosmosidentity.id]
  }
  ip_address_type = "Private"
  image_registry_credential {
    server   = "index.docker.io"
    username = var.docker_username
    password = var.docker_password
  }

  container {
    name   = var.mongodbcontainername
    image  = "mongo"
    cpu    = "0.5"
    memory = "1.5"

    ports {
      port     = 27017
      protocol = "TCP"
    }

    environment_variables = {
      MONGO_INITDB_ROOT_USERNAME = var.mongo_initdb_root_username
      MONGO_INITDB_ROOT_PASSWORD = var.mongo_initdb_root_password
    }

    volume {
      name                 = "mongo-data"
      mount_path           = "/data/db"
      storage_account_name = azurerm_storage_account.storage_acc.name
      storage_account_key  = azurerm_storage_account.storage_acc.primary_access_key
      share_name           = azurerm_storage_share.mongoshare.name
    }
  }
}

resource "azurerm_log_analytics_workspace" "laws" {
  name                = var.lawsname
  location            = azurerm_resource_group.rg.location
  resource_group_name = var.resource_group_name
  retention_in_days   = 30
}

resource "azurerm_application_insights" "appinsightsms1" {
  name                = "trdemoappinsightms1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = var.resource_group_name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.laws.id
}

resource "azurerm_application_insights" "appinsightsms2" {
  name                = "trdemoappinsightms2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = var.resource_group_name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.laws.id
}

resource "azurerm_key_vault_secret" "serverport" {
  name         = "serverport"
  value        = "20100"
  key_vault_id = data.azurerm_key_vault.kv1.id
}

resource "azurerm_key_vault_secret" "mongodburi" {
  name         = "springdatamongodburi"
  value        = "mongodb://${var.mongo_initdb_root_username}:${var.mongo_initdb_root_password}@${azurerm_container_group.mongocontainer.ip_address}:27017/demo-payment?authSource=admin"
  key_vault_id = data.azurerm_key_vault.kv1.id
}

resource "azurerm_key_vault_secret" "redishost" {
  name         = "springredishost"
  value        = "rediscachetrdemo.redis.cache.windows.net"
  key_vault_id = data.azurerm_key_vault.kv1.id
}

resource "azurerm_key_vault_secret" "redisport" {
  name         = "springredisport"
  value        = "6380"
  key_vault_id = data.azurerm_key_vault.kv1.id
}

resource "azurerm_key_vault_secret" "redisssl" {
  name         = "springredisssl"
  value        = "true"
  key_vault_id = data.azurerm_key_vault.kv1.id
}

resource "azurerm_key_vault_secret" "redispwd" {
  name         = "springredispassword"
  value        = azurerm_redis_cache.rediscache.primary_access_key
  key_vault_id = data.azurerm_key_vault.kv1.id
}

resource "azurerm_key_vault_secret" "eventhubconnectionstring" {
  name         = "azureeventhubconnectionstring"
  value        = azurerm_eventhub_namespace.eventhubns.default_primary_connection_string
  key_vault_id = data.azurerm_key_vault.kv1.id
}

resource "azurerm_key_vault_secret" "eventhubname" {
  name         = "azureeventhubname"
  value        = azurerm_eventhub.eh.name
  key_vault_id = data.azurerm_key_vault.kv1.id
}

resource "azurerm_key_vault_secret" "serverport2" {
  name         = "event-consumer-server-port"
  value        = "20101"
  key_vault_id = data.azurerm_key_vault.kv2.id
}

resource "azurerm_key_vault_secret" "filepath" {
  name         = "ENV-EVENTS-FILE-PATH"
  value        = "events.txt"
  key_vault_id = data.azurerm_key_vault.kv2.id
}

resource "azurerm_key_vault_secret" "kafkaservers" {
  name         = "kafka-bootstrap-servers"
  value        = "trdemoEventHubsNamespace.servicebus.windows.net:9093"
  key_vault_id = data.azurerm_key_vault.kv2.id
}

resource "azurerm_key_vault_secret" "kafkapassword" {
  name         = "kafka-password"
  value        = azurerm_eventhub_namespace.eventhubns.default_primary_connection_string
  key_vault_id = data.azurerm_key_vault.kv2.id
}

resource "azurerm_key_vault_secret" "eventhubname2" {
  name         = "ENV-EVENT-HUB-NAME"
  value        = azurerm_eventhub.eh.name
  key_vault_id = data.azurerm_key_vault.kv2.id
}


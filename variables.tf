variable "resource_group_name" {
  type = string
}

variable "location_eastus" {
  type = string
}

variable "vnet_name" {
  type = string
}

variable "subnet_name_pvt_endpoint" {
  type = string
}

variable "subnet_name_aci" {
  type = string
}

variable "subnet_name_vm" {
  type = string
}

variable "storage_acc_name" {
  type = string
}

variable "private_ep_name_storage" {
  type = string
}

variable "ep_conn_name" {
  type = string
}

variable "aci_pers_share_name" {
  type = string
}

variable "aci_mongo_share_name" {
  type = string
}

variable "ms1kvname" {
  type = string
}

variable "ms1identityname" {
  type = string
}

variable "ms2identityname" {
  type = string
}

variable "mongodbidentityname" {
  type = string
}

variable "ehnsname" {
  type = string
}

variable "ehname" {
  type = string
}

variable "cosmosdbaccname" {
  type = string
}

variable "private_ep_name_cosmos" {
  type = string
}

variable "rediscachename" {
  type = string
}

variable "private_ep_name_redis" {
  type = string
}

variable "containergroupname" {
  type = string
}

variable "mongodbcontainername" {
  type = string
}

variable "mongo_initdb_root_username" {
  type = string
}

variable "mongo_initdb_root_password" {
  type      = string
  sensitive = true
}

variable "lawsname" {
  type = string
}

variable "account_tier_standard" {
  type = string
}

variable "keyvault1_name" {
  type = string
}

variable "keyvault2_name" {
  type = string
}

variable "admin_principal_id" {
  type      = string
  sensitive = true
}

variable "keyvault_admin_role" {
  type = string
}

variable "keyvault_user_role" {
  type = string
}

variable "docker_username" {
  type = string
}

variable "docker_password" {
  type      = string
  sensitive = true
}

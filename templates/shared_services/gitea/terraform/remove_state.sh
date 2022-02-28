# !/bin/bash

#  ATTENTION:
#  The purpose of this script is to achieve backwards compatibility for deployment of TRE,
#  as some of the resources that were originally part of templates/core/terraform are now moved into their own Porter bundles.
#  (See https://github.com/microsoft/AzureTRE/issues/1177)
#  The intent is to remove the script once the clients have migrated.
#  General use of Terraform state manipulation is not recommended.

terraform init -input=false -backend=true -reconfigure -upgrade \
    -backend-config="resource_group_name=${MGMT_RESOURCE_GROUP_NAME}" \
    -backend-config="storage_account_name=${MGMT_STORAGE_ACCOUNT_NAME}" \
    -backend-config="container_name=${TERRAFORM_STATE_CONTAINER_NAME}" \
    -backend-config="key=${TRE_ID}"

function remove_if_present() {
  terraform state show $1
  if [[ $? -eq 0 ]]; then
    terraform state rm $1
  fi
}

remove_if_present module.gitea[0].azurerm_app_service.gitea
remove_if_present module.gitea[0].azurerm_app_service_virtual_network_swift_connection.gitea-integrated-vnet
remove_if_present module.gitea[0].azurerm_firewall_application_rule_collection.web_app_subnet_gitea
remove_if_present module.gitea[0].azurerm_key_vault_access_policy.gitea_policy
remove_if_present module.gitea[0].azurerm_key_vault_secret.db_password
remove_if_present module.gitea[0].azurerm_key_vault_secret.gitea_password
remove_if_present module.gitea[0].azurerm_monitor_diagnostic_setting.webapp_gitea
remove_if_present module.gitea[0].azurerm_mysql_database.gitea
remove_if_present module.gitea[0].azurerm_mysql_server.gitea
remove_if_present module.gitea[0].azurerm_private_endpoint.gitea_private_endpoint
remove_if_present module.gitea[0].azurerm_private_endpoint.private-endpoint
remove_if_present module.gitea[0].azurerm_role_assignment.gitea_acrpull_role
remove_if_present module.gitea[0].azurerm_storage_share.gitea
remove_if_present module.gitea[0].azurerm_user_assigned_identity.gitea_id
remove_if_present module.gitea[0].null_resource.webapp_vault_access_identity
remove_if_present module.gitea[0].random_password.gitea_passwd
remove_if_present module.gitea[0].random_password.password

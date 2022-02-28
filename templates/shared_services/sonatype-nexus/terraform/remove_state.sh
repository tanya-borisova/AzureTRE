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

remove_if_present module.nexus[0].azurerm_app_service.nexus
remove_if_present module.nexus[0].azurerm_app_service_virtual_network_swift_connection.nexus-integrated-vnet
remove_if_present module.nexus[0].azurerm_firewall_application_rule_collection.web_app_subnet_nexus
remove_if_present module.nexus[0].azurerm_monitor_diagnostic_setting.nexus
remove_if_present module.nexus[0].azurerm_private_endpoint.nexus_private_endpoint
remove_if_present module.nexus[0].azurerm_storage_share.nexus
remove_if_present module.nexus[0].null_resource.upload_nexus_props

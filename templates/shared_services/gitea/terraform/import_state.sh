#!/bin/bash

set -x

function showUsage() {
    cat <<USAGE

    ATTENTION:
    The purpose of this script is to achieve backwards compatibility for deployment of TRE,
    as some of the resources that were originally part of templates/core/terraform are now moved into their own Porter bundles.
    (See https://github.com/microsoft/AzureTRE/issues/1177)
    The intent is to remove the script once the clients have migrated.
    General use of Terraform state manipulation is not recommended.

    Usage: $0 [-g | --mgmt-resource-group-name ]  [-s | --mgmt-storage-account-name] [-n | --state-container-name] [-k | --key]

    Options:
        -g, --mgmt-resource-group-name      Management resource group name
        -s, --mgmt-storage-account-name     Management storage account name
        -n, --state-container-name          State container name
        -k, --key                           Terraform State Key
USAGE
    exit 1
}

# if no arguments are provided, return showUsage function
if [ $# -eq 0 ]; then
    showUsage # run showUsage function
fi

while [ "$1" != "" ]; do
    case $1 in
    -g | --mgmt-resource-group-name)
        shift
        MGMT_RESOURCE_GROUP_NAME=$1
        ;;
    -s | --mgmt-storage-account-name)
        shift
        MGMT_STORAGE_ACCOUNT_NAME=$1
        ;;
    -n | --state-container-name)
        shift
        CONTAINER_NAME=$1
        ;;
    -k | --key)
        shift
        KEY=$1
        ;;
    *)
       showUsage
        ;;
    esac
    shift # remove the current value for `$1` and use the next
done


if [[ -z ${MGMT_RESOURCE_GROUP_NAME+x} ]]; then
    echo -e "No terraform state resource group name provided\n"
   showUsage
fi

if [[ -z ${MGMT_STORAGE_ACCOUNT_NAME+x} ]]; then
    echo -e "No terraform state storage account name provided\n"
   showUsage
fi

if [[ -z ${CONTAINER_NAME+x} ]]; then
    echo -e "No terraform state container name provided\n"
   showUsage
fi

if [[ -z ${KEY+x} ]]; then
    echo -e "No KEY provided\n"
   showUsage
fi

RESOURCE_GROUP_ID="rg-${TRE_ID}"

# Initialsie state for Terraform, login to az to look up resources
pushd /cnab/app/terraform
terraform init -input=false -backend=true -reconfigure -upgrade \
    -backend-config="resource_group_name=${MGMT_RESOURCE_GROUP_NAME}" \
    -backend-config="storage_account_name=${MGMT_STORAGE_ACCOUNT_NAME}" \
    -backend-config="container_name=${CONTAINER_NAME}" \
    -backend-config="key=${KEY}"
az login --service-principal --username ${ARM_CLIENT_ID} --password ${ARM_CLIENT_SECRET} --tenant ${ARM_TENANT_ID}

# Import a resource if it exists in Azure but doesn't exist in Terraform
function import_if_exists() {
  ADDRESS=$1
  ID=$2
  CMD=$3

  # Check if the resource exists in Terraform
  terraform state show ${ADDRESS}
  TF_RESOURCE_EXISTS=$?
  # Some resources, e.g. Firewall rules and Diagnostics, don't show up in `az resource show`,
  # so we need a way to set up a custom command for them
  if [[ -z ${CMD} ]]; then
    CMD="az resource show --ids ${ID}"
  fi
  ${CMD}
  AZ_RESOURCE_EXISTS=$?

  # If resource exists in Terraform, it's already managed -- don't do anything
  # If resource doesn't exist in Terraform and doesn't exist in Azure, it will be created -- don't do anything
  # If resource doesn't exist in Terraform but exist in Azure, we need to import it
  if [[ ${TF_RESOURCE_EXISTS} -ne 0 && ${AZ_RESOURCE_EXISTS} -eq 0 ]]; then
    echo "IMPORTING ${ADDRESS} ${ID}"
    terraform import -var 'tre_id=${TRE_ID}' -var 'location=${LOCATION}' ${ADDRESS} ${ID}
  fi
}

import_if_exists azurerm_firewall_application_rule_collection.web_app_subnet_gitea \
  "/subscriptions/${ARM_SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_ID}/providers/Microsoft.Network/azureFirewalls/fw-${TRE_ID}/applicationRuleCollections/arc-web_app_subnet_gitea"

import_if_exists azurerm_user_assigned_identity.gitea_id \
  "/subscriptions/${ARM_SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_ID}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-gitea-${TRE_ID}"

import_if_exists azurerm_storage_share.gitea \
  "https://stg${TRE_ID}.file.core.windows.net/gitea-data"

import_if_exists azurerm_mysql_server.gitea \
  "/subscriptions/${ARM_SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP_ID}/providers/Microsoft.DBforMySQL/servers/mysql-${TRE_ID}"

# remove_if_present module.gitea[0].azurerm_app_service.gitea
# remove_if_present module.gitea[0].azurerm_app_service_virtual_network_swift_connection.gitea-integrated-vnet
# remove_if_present module.gitea[0].azurerm_key_vault_access_policy.gitea_policy
# remove_if_present module.gitea[0].azurerm_key_vault_secret.db_password
# remove_if_present module.gitea[0].azurerm_key_vault_secret.gitea_password
# remove_if_present module.gitea[0].azurerm_monitor_diagnostic_setting.webapp_gitea
# remove_if_present module.gitea[0].azurerm_mysql_database.gitea
# remove_if_present module.gitea[0].azurerm_private_endpoint.gitea_private_endpoint
# remove_if_present module.gitea[0].azurerm_private_endpoint.private-endpoint
# remove_if_present module.gitea[0].azurerm_role_assignment.gitea_acrpull_role
# remove_if_present module.gitea[0].null_resource.webapp_vault_access_identity
# remove_if_present module.gitea[0].random_password.gitea_passwd
# remove_if_present module.gitea[0].random_password.password

popd

#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Source: https://learn.microsoft.com/en-us/azure/azure-functions

# App Default Values
APP="AzureFunction"
var_tags="serverless"
var_cpu="2"
var_ram="2048"
var_disk="10"
var_os="ubuntu"
var_version="22.04"
var_unprivileged="1"

# App Output & Base Settings
header_info "$APP"
base_settings

# Core
variables
color
catch_errors

function update_script() {
    header_info
    check_container_storage
    check_container_resources
    if [[ ! -f /usr/local/bin/azure-functions-core-tools ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    msg_info "Updating ${APP} LXC"
    apt-get update &>/dev/null
    apt-get -y upgrade &>/dev/null
    msg_ok "Updated Successfully"
    exit
}

function install_azure_function_tools() {
    msg_info "Installing Azure Functions Core Tools"
    curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
    mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
    echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" > /etc/apt/sources.list.d/azure-cli.list
    apt-get update &>/dev/null
    apt-get install -y azure-functions-core-tools-4 &>/dev/null
    msg_ok "Azure Functions Core Tools Installed"
}

start
build_container
install_azure_function_tools
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"

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
    
    # Running apt-get update and upgrade without redirection to see errors
    sudo apt-get update   # Show output to debug errors
    if [ $? -ne 0 ]; then
        msg_error "Failed to update repositories!"
        exit 1
    fi
    
    sudo apt-get -y upgrade   # Show output to debug errors
    if [ $? -ne 0 ]; then
        msg_error "Failed to upgrade packages!"
        exit 1
    fi
    
    msg_ok "Updated Successfully"
    exit
}

function install_azure_function_tools() {
    msg_info "Installing Azure Functions Core Tools"
    
    # Fetch and add Microsoft's GPG key
    curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
    if [ $? -ne 0 ]; then
        msg_error "Failed to fetch and add Microsoft's GPG key!"
        exit 1
    fi

    # Move the GPG key to trusted location
    sudo mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
    if [ $? -ne 0 ]; then
        msg_error "Failed to move Microsoft's GPG key!"
        exit 1
    fi

    # Add the Microsoft Azure CLI repository to apt sources list
    echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/azure-cli.list
    if [ $? -ne 0 ]; then
        msg_error "Failed to add Azure CLI repository!"
        exit 1
    fi
    
    # Run apt-get update and install Azure Functions Core Tools
    sudo apt-get update   # Show output to debug errors
    if [ $? -ne 0 ]; then
        msg_error "Failed to update repositories after adding Azure CLI!"
        exit 1
    fi
    
    sudo apt-get install -y azure-functions-core-tools-4   # Show output to debug errors
    if [ $? -ne 0 ]; then
        msg_error "Failed to install Azure Functions Core Tools!"
        exit 1
    fi
    
    msg_ok "Azure Functions Core Tools Installed"
}

# Start the process
start
build_container

# Call the installation function
install_azure_function_tools

# Describe the completion message
description

# Final Success Message
msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"

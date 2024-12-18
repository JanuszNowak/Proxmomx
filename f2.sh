#!/bin/bash

# Variables
CONTAINER_ID="222"  # Change to the desired LXC container ID
CONTAINER_NAME="azure-functions-container"
OS_TEMPLATE="ubuntu-22.04-standard_22.04-1_amd64.tar.gz"  # Adjust if needed
MEMORY="2048"  # MB
SWAP="1024"  # MB
DISK="8"  # GB

# Create LXC container
echo "Creating LXC container..."
pct create $CONTAINER_ID /var/lib/vz/template/cache/$OS_TEMPLATE -hostname $CONTAINER_NAME -rootfs local-lvm:$DISK -memory $MEMORY -swap $SWAP -net0 name=eth0,bridge=vmbr0,ip=dhcp
pct start $CONTAINER_ID
echo "LXC container created and started."

# Enter the container
echo "Entering the container..."
pct enter $CONTAINER_ID <<'EOF'

# Update the container and install dependencies
echo "Updating system and installing dependencies..."
apt update && apt upgrade -y
apt install -y curl gnupg2 lsb-release ca-certificates sudo

# Install Node.js
echo "Installing Node.js..."
curl -sL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

# Add Microsoft repository for Azure CLI
echo "Adding Microsoft repository..."
curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
mv microsoft.gpg /etc/apt/trusted.gpg.d/microsoft.gpg
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" > /etc/apt/sources.list.d/azure-cli.list

# Install Azure Functions Core Tools 4
echo "Installing Azure Functions Core Tools..."
apt update
apt install -y azure-functions-core-tools-4

# Verify installation
echo "Verifying Azure Functions Core Tools installation..."
func --version

# Create a new Azure Function app
echo "Creating a new Azure Function app..."
mkdir /root/my-azure-function
cd /root/my-azure-function
func init MyFunctionApp --worker-runtime node

# Create a new function (HTTP trigger)
echo "Creating a new HTTP trigger function..."
func new

# Start the function locally
echo "Starting the function locally..."
func start

EOF

echo "Setup completed successfully!"

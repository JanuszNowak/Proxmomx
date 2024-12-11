#!/bin/bash

set -euo pipefail

YW=${YW:-"\033[33m"}
BL=${BL:-"\033[36m"}
GN=${GN:-"\033[1;92m"}
CL=${CL:-"\033[m"}

# Functions
header_info() {
  echo -e "${YW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CL}"
  echo -e "${BL}  🚀 Proxmox Apache Spark LXC Container Setup Script${CL}"
  echo -e "${YW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CL}"
}

error_exit() {
  echo -e "${YW}[ERROR] $1${CL}" >&2
  exit 1
}

success_message() {
  echo -e "${GN}[SUCCESS] $1${CL}"
}

header_info

# Variables
TEMPLATE_ID=9000  # Replace with your Proxmox template ID for Ubuntu
CONTAINER_ID=101  # Desired container ID
CONTAINER_NAME="spark-lxc"
CONTAINER_DISK_SIZE="10G"  # Disk size for the container
CONTAINER_MEMORY="4096"  # Memory in MB
CONTAINER_CORES="2"  # Number of cores
SPARK_VERSION="3.5.0"  # Replace with desired Spark version
JAVA_PACKAGE="openjdk-11-jdk"  # Replace with required JDK version
BRIDGE="vmbr0"  # Network bridge
IP_ADDRESS="192.168.1.100"  # Replace with desired IP
GATEWAY="192.168.1.1"  # Replace with your gateway

# Ensure TEMPLATE_ID is provided
if ! pct list | grep -q $TEMPLATE_ID; then
  error_exit "Template ID $TEMPLATE_ID not found. Please upload the template first."
fi

# Step 1: Create LXC Container
header_info
echo -e "${BL}Creating LXC container $CONTAINER_NAME (${CONTAINER_ID})...${CL}"
if pct create $CONTAINER_ID local:vztmpl/ubuntu-20.04-standard_${TEMPLATE_ID}.tar.gz \
  -hostname $CONTAINER_NAME \
  -rootfs local-lvm:$CONTAINER_DISK_SIZE \
  -memory $CONTAINER_MEMORY \
  -cores $CONTAINER_CORES \
  -net0 name=eth0,bridge=$BRIDGE,ip=$IP_ADDRESS/24,gw=$GATEWAY; then
  success_message "Container $CONTAINER_NAME created successfully."
else
  error_exit "Failed to create container."
fi

# Start the container
header_info
echo -e "${BL}Starting container $CONTAINER_NAME...${CL}"
pct start $CONTAINER_ID || error_exit "Failed to start container."

# Step 2: Install Dependencies
header_info
echo -e "${BL}Installing dependencies inside container...${CL}"
pct exec $CONTAINER_ID -- bash -c "apt-get update && apt-get install -y $JAVA_PACKAGE wget tar" || error_exit "Failed to install dependencies."

# Step 3: Download and Install Spark
header_info
echo -e "${BL}Downloading and installing Apache Spark...${CL}"
pct exec $CONTAINER_ID -- bash -c "\
  wget https://downloads.apache.org/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz && \
  tar -xvzf spark-${SPARK_VERSION}-bin-hadoop3.tgz -C /opt && \
  mv /opt/spark-${SPARK_VERSION}-bin-hadoop3 /opt/spark && \
  rm spark-${SPARK_VERSION}-bin-hadoop3.tgz" || error_exit "Failed to download or install Spark."

# Step 4: Configure Spark Environment
header_info
echo -e "${BL}Configuring Spark environment...${CL}"
pct exec $CONTAINER_ID -- bash -c "\
  echo 'export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64' >> /etc/profile && \
  echo 'export SPARK_HOME=/opt/spark' >> /etc/profile && \
  echo 'export PATH=\$SPARK_HOME/bin:\$JAVA_HOME/bin:\$PATH' >> /etc/profile && \
  source /etc/profile" || error_exit "Failed to configure environment."

# Step 5: Verify Spark Installation
header_info
echo -e "${BL}Verifying Spark installation...${CL}"
pct exec $CONTAINER_ID -- bash -c "/opt/spark/bin/spark-shell --version" || error_exit "Spark verification failed."

# Finished
success_message "Apache Spark LXC container $CONTAINER_NAME has been set up successfully."

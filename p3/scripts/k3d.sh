#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

USERNAME=cpoulain

# check permissions
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root or use sudo.${NC}"
    exit 1
fi

# Install and create k3d cluster
printf "${GREEN}[K3D]${NC} - Installing and creating k3d cluster...\n"
if k3d cluster list | grep -q "$USERNAME"; then
    printf "${YELLOW}[K3D]${NC} - k3d cluster for user ${USERNAME} already exists. Skipping creation.\n"
    exit 1
else
    if ! sudo k3d cluster create $USERNAME --port 80:80@loadbalancer --servers 1 --agents 3; then
        printf "${RED}[K3D] - Failed to create k3d cluster for user ${USERNAME}.\nIs K3D install ? Is docker service running ?${NC}\n"
        exit 1
    fi
fi

export KUBECONFIG=$(k3d kubeconfig write $USERNAME)
printf "${GREEN}[K3D] - k3d cluster for user ${USERNAME} created successfully.${NC}\n"
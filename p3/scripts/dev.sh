#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# check permissions
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root or use sudo.${NC}"
    exit 1
fi

# Install and laucnh dev app
printf "${GREEN}[DEV]${NC} - Installing and launching dev app...\n"
kubectl apply -f ./confs/dev/namespace.yaml
kubectl apply -n argocd -f ./confs/dev/app.yaml > /dev/null
kubectl apply -n dev -f ./confs/dev/ingress.yaml > /dev/null
printf "${GREEN}[DEV]${NC} - Dev app installation and setup complete and available at: http://localhost/dev .\n"
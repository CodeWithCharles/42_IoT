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

# Install and laucnh ArgoCD
kubectl apply -f ./confs/argocd/namespace.yaml
kubectl apply -n argocd -f ./confs/argocd/resource.yaml > /dev/null
kubectl apply -f ./confs/argocd/configmap.yaml > /dev/null

# Wait for ArgoCD server to be ready
printf "${GREEN}[ARGOCD]${NC} - Waiting for ArgoCD server to be ready...\n"
while true; do
    status=$(kubectl -n argocd get pods -l app.kubernetes.io/name=argocd-server -o jsonpath="{.items[0].status.phase}")
    if [ "$status" == "Running" ]; then
        printf "${GREEN}[ARGOCD]${NC} - ArgoCD server is running.\n"
        break
    else
        printf "${YELLOW}[ARGOCD]${NC} - ArgoCD server status: $status. Waiting...\n"
        sleep 5
    fi
done

# Restart ArgoCD server to apply configuration
printf "${GREEN}[ARGOCD]${NC} - Restarting ArgoCD server to apply configuration...\n"
kubectl rollout restart deployment argocd-server -n argocd > /dev/null
kubectl rollout status deployment argocd-server -n argocd --timeout=60s > /dev/null

# Network settings for ArgoCD server access
printf "${GREEN}[ARGOCD]${NC} - Setting up network access for ArgoCD server...\n"
kubectl apply -n argocd -f ./confs/argocd/ingress.yaml
printf "${GREEN}[ARGOCD]${NC} - Network access setup complete.\n"

# Getting initial admin password
printf "${GREEN}[ARGOCD]${NC} - Retrieving initial admin password...\n"
initial_password=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
printf "${GREEN}[ARGOCD]${NC} - login: admin | password: ${YELLOW}${initial_password}${NC}\n"
printf "${GREEN}[ARGOCD]${NC} - ArgoCD installation and setup complete and available at: http://localhost/argocd .\n"
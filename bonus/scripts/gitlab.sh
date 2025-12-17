#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ------------------------------ Sudo safe guard ----------------------------- #
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root or use sudo.${NC}"
    exit 1
fi

# ------------------------------- Gitlab confs ------------------------------- #
printf "${GREEN}[GITLAB]${NC} - Installing and launching app...\n"
kubectl apply -f ./confs/gitlab/namespace.yaml
kubectl apply -n gitlab -f ./confs/gitlab/volume.yaml > /dev/null
kubectl apply -n gitlab -f ./confs/gitlab/deployment.yaml > /dev/null
kubectl apply -n gitlab -f ./confs/gitlab/service.yaml > /dev/null


# --------------------- Wait for gitlab pods to be ready --------------------- #
printf "${GREEN}[GITLAB]${NC} - Waiting for GitLab pods to be ready...\n"
while true; do
    status=$(sudo kubectl get pods -n gitlab --field-selector=status.phase=Running 2>/dev/null | grep -c "gitlab")
    if [ "$status" -eq "1" ]; then
        printf "${GREEN}[GITLAB]${NC} - GitLab pods are running.\n"
        break
    else
        printf "${YELLOW}[GITLAB]${NC} - GitLab pod status: $status/1. Waiting...\n"
        sleep 5
    fi
done

# ------------------------------- Apply ingress ------------------------------ #
kubectl apply -n gitlab -f ./confs/gitlab/ingress.yaml

# -------------------- Wait for gitlab service to be ready ------------------- #
printf "${GREEN}[GITLAB]${NC} - Waiting for GitLab service to be ready.\n"
response="000"
while [[ "$response" != "302" ]]; do
    response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/gitlab/ || echo "000")
    if [[ "$response" == "302" ]]; then
        break
    else
	    printf "${YELLOW}[GITLAB]${NC} - GitLab service status: $response. Waiting...\n"
	    sleep 5
    fi
done

# ------ Get initial root password and save it to .gitlab_password file ------ #
password=$(sudo kubectl exec -n gitlab $(sudo kubectl get pods -n gitlab -l app=gitlab -o jsonpath='{.items[0].metadata.name}') -- cat /etc/gitlab/initial_root_password | awk '/Password:/ {print $2}')
echo "$password" > .gitlab_password

# ------------------------------- Final output ------------------------------- #
echo "gitlab available at: http://localhost/gitlab"
echo "login: root, password: $password"
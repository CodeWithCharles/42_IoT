#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

REPO_NAME="42_IoT_Playground_cpoulain"
GITHUB_USERNAME="CodeWithCharles"
GITHUB_REPO_URL="https://github.com/${GITHUB_USERNAME}/${REPO_NAME}.git"
GITLAB_URL="http://localhost/gitlab/"
GITLAB_ORIGIN_URL="${GITLAB_URL}root/${REPO_NAME}.git"
CURRENT_DIR=$(pwd)

# ----------------- Function to get local gitlab access token ---------------- #
get_gitlab_access_token() {
    curl_response=$(curl --silent --show-error --request POST \
        --form "grant_type=password" --form "username=root" \
        --form "password=$(cat .gitlab_password)" "$GITLAB_URL/oauth/token")

    access_token=$(echo "$curl_response" | grep -o '"access_token":"[^"]*' | cut -d':' -f2 | tr -d '"')
    echo "$access_token"
}

# ---------------------------- Create gitlab repo ---------------------------- #
create_gitlab_repo() {
    access_token="$1"
    curl_response=$(curl --silent --show-error --request POST \
        --header "Authorization: Bearer $access_token" --form "name=$REPO_NAME" \
        --form "visibility=public" "$GITLAB_URL/api/v4/projects")
}

# ----------------------- Clone github repo playground ----------------------- #
clone_github_repo() {
    rm -rf /tmp/"$REPO_NAME"
    git clone "$GITHUB_REPO_URL" /tmp/"$REPO_NAME"
}

# ----------------------------- Check permissions ---------------------------- #
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root or use sudo.${NC}"
    exit 1
fi

echo -e "${YELLOW}Deploying playground repo to gitlab.${NC}\n"

# ----------------------------- Clone github repo ---------------------------- #
printf "${GREEN}[DEV]${NC} - Clone github repo...\n"
clone_github_repo
access_token=$(get_gitlab_access_token)


# ---------------------------- Create gitlab repo ---------------------------- #
printf "${GREEN}[DEV]${NC} - Create gitlab repo...\n"
create_gitlab_repo "$access_token"


# ---------------------- Add gitlab remote to local repo --------------------- #
cd /tmp/"$REPO_NAME"
gitlab_repo_url_with_token="http://oauth2:$access_token@localhost/gitlab/root/${REPO_NAME}.git"
git remote add gitlab "$gitlab_repo_url_with_token"


# --------------------------- Push into gitlab repo -------------------------- #
printf "${GREEN}[DEV]${NC} - Push local repo into local gitlab...\n"
echo -e "${YELLOW}Pushing to GitLab...${NC}\n"
git push --set-upstream gitlab master
cd "$CURRENT_DIR"

# ------------------------ Install dev and launch app ------------------------ #
printf "${GREEN}[DEV]${NC} - Installing and launching dev app...\n"
kubectl apply -f ./confs/dev/namespace.yaml
kubectl apply -n argocd -f ./confs/dev/app.yaml > /dev/null
kubectl apply -n dev -f ./confs/dev/ingress.yaml > /dev/null
printf "${GREEN}[DEV]${NC} - Dev app installation and setup complete and available at: http://localhost/dev .\n"
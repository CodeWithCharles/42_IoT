#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

check_install()
{
    local name=$1
    local command=$2
    local install_cmd=$3

    if $command &> /dev/null; then
        echo -e "${GREEN}[${name^^}] - $name is already installed.${NC}"
    else
        echo -e "${YELLOW}[${name^^}] - $name is not installed. Installing...${NC}"
        eval $install_cmd
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}[${name^^}] - $name installed successfully.${NC}"
        else
            echo -e "${RED}[${name^^}] - Failed to install $name.${NC}"
            exit 1
        fi
    fi
}

# check permissions
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root or use sudo.${NC}"
    exit 1
fi

echo -e "${YELLOW}Installing project dependencies...${NC}"

# Update package lists
printf "${GREEN}[LINUX]${NC} - Getting updates...\n"
apt-get update > /dev/null
if [ $? -ne 0 ]; then
    echo -e "${RED}Failed to update package lists. Please check your network connection.${NC}"
    exit 1
fi
printf "${GREEN}[LINUX]${NC} - Done getting updates.\n"

# Check and install Git
printf "${GREEN}[GIT]${NC} - Installing GIT...\n"
check_install "Git" "git --version" "apt-get install -y git"

# Check and install curl
printf "${GREEN}[CURL]${NC} - Installing curl...\n"
check_install "curl" "curl --version" "apt-get install -y curl"

# Check and install docker
printf "${GREEN}[DOCKER]${NC} - Installing docker...\n"
check_install "Docker" "docker --version" "
apt remove $(dpkg --get-selections docker.io docker-compose docker-doc podman-docker containerd runc 2>/dev/null | cut -f1)
&& apt-get update > /dev/null
&& apt-get install -y ca-certificates gnupg lsb-release > /dev/null
&& mkdir -m 0755 -p /etc/apt/keyrings
&& curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
&& chmod a+r /etc/apt/keyrings/docker.asc
&& tee /etc/apt/sources.list.d/docker.sources <<EOF
&& apt-get update > /dev/null
&& apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin > /dev/null
&& usermod -aG docker \$USER > /dev/null
&& systemctl status docker
&& echo -e \"${YELLOW}Please reboot your system to update docker permissions${NC}\"
"

# Check and install kubectl
printf "${GREEN}[KUBECTL]${NC} - Installing kubectl...\n"
check_install "kubectl" "kubectl version --client" "
curl -LO \"https://dl.k8s.io/release/\$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl\"
&& chmod +x kubectl
&& mv kubectl /usr/local/bin/
"

printf "${GREEN}[K3D]${NC} - Installing k3d...\n"
check_install "k3d" "k3d --version" "
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
"

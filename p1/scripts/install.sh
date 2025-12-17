#!/bin/bash

# Script de verification des dependances pour IoT
# Verifie la presence et les versions de Vagrant, VB, kubectl, K3s, Docker

set +e # pour continuer meme en cas d'erreur, on check toutes les deps

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # reset

ERRORS=0
WARNINGS=0

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}   Verification des dependances - IoT Project${NC}"
echo -e "${BLUE}================================================${NC}\n"

check_command() {
    local cmd=$1
    local name=$2
    local required=$3

    if command -v $cmd &> /dev/null; then
        local version=$($cmd --version 2>&1 | head -n 1)
        echo -e "${GREEN}ok ==> ${NC} $name est installe"
        echo -e " Version: $version"
        return 0
    else
        if [ "$required" = "true" ]; then
            echo -e "${RED}ko ==> {NC} $name n'est pas installe ${RED}(REQUIS)${NC}"
            ((ERRORS++))
        else
            echo -e "${YELLOW}ko ==> {NC} $name n'est pas installe (optionnel)"
            ((WARNINGS++))
        fi
        return 1
    fi
}


echo -e "\n${BLUE}[1 / 2] VirtualBox${NC}"
if command -v vboxmanage &> /dev/null; then
    version=$(vboxmanage --version)
    echo -e "${GREEN}ok ==> ${NC} VirtualBox est installe"
    echo -e "  Version: $version"

    # est-ce que VB peut lister les VM ? 
    if vboxmanage list vms &> /dev/null; then
        echo -e "${GREEN}ok ==> ${NC} VirtualBox fonctionne correctement"
    else
        echo -e "${RED}ko ==> ${NC} VirtualBox semble avoir un probleme"
        ((ERRORS++))
    fi
else
    echo -e "${RED}ko ==> ${NC} VirtualBox n'est PAS installe ${RED}(REQUIS)${NC}"
    ((ERRORS++))
fi


# DOCKER
echo -e "\n${BLUE}[2 / 2] Docker${NC}"
if check_command "docker" "Docker" "false"; then
    # docker accessible sans les droits sudo ? 
    if docker ps &> /dev/null; then
        echo -e "${GREEN}ok ==> ${NC} Docker est accessible"
    else
        echo -e "  ${YELLOW}: ko${NC}, Docker necessite les droits sudo ou n'est pas demarre sur votre machine"
        echo -e "  Lancez: sudo systemctl start docker"
        echo -e "  Sinon, ajoutez votre user au groupe docker: sudo usermod -aG docker \$USER"
    fi
fi

# Verification de l'espace disque
echo -e "\n${BLUE}Espace disque disponible:${NC}"
df -h / | tail -n 1 | awk '{print "  Disponible: " $4 " sur " $2 " (" $5 " utilise)"}'

# Verification de la RAM disponible
echo -e "\n${BLUE}RAM disponible:${NC}"
free -h | grep "Mem:" | awk '{print "  Total: " $2 " | Disponible: " $7}'
echo -e "  ${YELLOW}Note:${NC} Le projet necessite ~1.5GB de RAM pour les VMs"

# Verification du reseau VirtualBox
echo -e "\n${BLUE}Reseaux VirtualBox:${NC}"
if command -v vboxmanage &> /dev/null; then
    vboxmanage list hostonlyifs 2>/dev/null | grep -E "Name:|IPAddress:" | head -n 4
    if [ $? -ne 0 ]; then
        echo -e "  ${YELLOW}⚠${NC} Aucun reseau host-only configure"
        echo -e "    Vagrant le creera automatiquement au premier 'vagrant up'"
    fi
fi

# Verification de la presence des fichiers du projet
echo -e "\n${BLUE}Structure du projet:${NC}"
if [ -f "Vagrantfile" ]; then
    echo -e "${GREEN}✓${NC} Vagrantfile present"
else
    echo -e "${RED}✗${NC} Vagrantfile manquant dans le repertoire courant"
    ((ERRORS++))
fi

if [ -d "scripts" ]; then
    echo -e "${GREEN}✓${NC} Dossier scripts/ present"
    [ -f "scripts/install_k3s_server.sh" ] && echo -e "  ${GREEN}✓${NC} install_k3s_server.sh" || echo -e "  ${RED}✗${NC} install_k3s_server.sh manquant"
    [ -f "scripts/install_k3s_agent.sh" ] && echo -e "  ${GREEN}✓${NC} install_k3s_agent.sh" || echo -e "  ${RED}✗${NC} install_k3s_agent.sh manquant"
else
    echo -e "${RED}✗${NC} Dossier scripts/ manquant"
    ((ERRORS++))
fi

# Verification des permissions d'execution
if [ -f "scripts/install_k3s_server.sh" ] && [ -x "scripts/install_k3s_server.sh" ]; then
    echo -e "  ${GREEN}✓${NC} Scripts executables"
else
    echo -e "  ${YELLOW}⚠${NC} Scripts sans permissions d'execution"
    echo -e "    Lancez: chmod +x scripts/*.sh"
    ((WARNINGS++))
fi

# Sommaire
echo -e "\n${BLUE}================================================${NC}"
echo -e "${BLUE}                    SOMMAIRE${NC}"
echo -e "${BLUE}================================================${NC}"

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ Tout est OK !${NC} Vous pouvez lancer 'vagrant up'"
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ ${WARNINGS} avertissement(s)${NC} - Le projet devrait fonctionner glhf pour debug"
    echo -e "  Vous pouvez lancer 'vagrant up'"
else
    echo -e "${RED}✗ ${ERRORS} erreur(s) bloquante(s)${NC}"
    echo -e "${YELLOW}⚠ ${WARNINGS} avertissement(s)${NC}"
    echo -e "\n${RED}Installez les dependances manquantes avant de continuer !${NC}"
fi

echo -e "\n${BLUE}Commandes utiles:${NC}"
echo -e "  vagrant up               - Demarrer les VMs"
echo -e "  vagrant ssh cpoulainS    - Se connecter au serveur"
echo -e "  vagrant ssh cpoulainSW   - Se connecter au worker"
echo -e "  vagrant status           - Voir l'etat des VMs"
echo -e "  vagrant destroy -f       - Detruire les VMs"

exit $ERRORS
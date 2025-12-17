#!/bin/bash

set -e

echo "Debut de l'installation de K3s en mode agent ... "

# Update system and install netcat for connectivity testing
apt-get update -qq && apt-get install -y netcat-openbsd

# Wait for server to be available
echo "En attente du serveur K3s"
while ! nc -z 192.168.56.110 6443 2>/dev/null; do
    echo "En attente du serveur K3s sur 192.168.56.110:6443..."
    sleep 3
done

# Wait for token to be available
echo "En attente du node-token ..."
while [ ! -f /vagrant/node-token ]; do 
    echo "En attente du node token file..."
    sleep 3
done

# Install K3s in agent mode
echo "Installation de K3s en mode agent ..."
TOKEN=$(cat /vagrant/node-token)
curl -sfL https://get.k3s.io | K3S_TOKEN="$TOKEN" sh -s - agent \
    --server=https://192.168.56.110:6443 --flannel-iface=eth1

echo "K3s en mode agent est pret !"

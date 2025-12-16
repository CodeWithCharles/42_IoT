#!/bin/bash

set -e

echo "Debut de l'installation de K3s en mode serveur ..."

# Update system
apt-get update -qq

# Install K3s in server mode
curl -sfL https://get.k3s.io | sh -s - server --flannel-iface=eth1

# Wait for K3s to be ready
echo "En attente de K3s"
while [ ! -f /var/lib/rancher/k3s/server/node-token ]; do 
    sleep 2
done

# Copy token and kubeconfig for worker node
echo "Copie du node-token && de kubeconfig pour le worker ..."
sudo cp /var/lib/rancher/k3s/server/node-token /vagrant/node-token 2>/dev/null || true
sudo cp /etc/rancher/k3s/k3s.yaml /vagrant/k3s.yaml 2>/dev/null || true
sudo chmod 644 /vagrant/node-token /vagrant/k3s.yaml 2>/dev/null || true

echo "Installation de K3s en mode serveur reussie !"

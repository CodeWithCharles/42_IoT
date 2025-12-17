#!/bin/bash

set -e

echo "Installation de kubectl ..."

# telecharger latest stable de k8s
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# installer kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

# verif install
kubectl version --client

echo "kubectl installe avec succes !"

# configurer kubectl pour utiliser K3s config
if [ -f /etc/rancher/k3s/k3s.yaml ]; then
    echo "Configuration de kubectl pour K3s ..."
    mkdir -p /home/vagrant/.kube
    sudo cp /etc/rancher/k3s/k3s.yaml /home/vagrant/.kube/config
    sudo chown vagrant:vagrant /home/vagrant/.kube/config
    export KUBECONFIG=/home/vagrant/.kube/config
    echo "export KUBECONFIG=/home/vagrant/.kube/config" >> /home/vagrant/.bashrc
    echo "kubectl configure pour K3s !"
fi

# creation d'alisa
echo "Creation des alias kubectl ..."
cat >> /home/vagrant/.bashrc << 'EOF'

# Kubectl aliases
alias k='kubectl'
alias kgn='kubectl get nodes'
alias kgp='kubectl get pods -A'
alias kgs='kubectl get svc -A'
alias kgd='kubectl get deployments -A'
EOF

echo "Aliases crees ! (k, kgn, kgp, kgs, kgd)"
echo "Relancez 'source ~/.bashrc' ou reconnectez-vous pour les activer"
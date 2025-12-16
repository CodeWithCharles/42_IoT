#!/bin/bash

set -e

echo "En attente, il faut que K3s soit pret ..."
while ! kubectl get nodes 2>/dev/null | grep -q "Ready"; do
    sleep 2
done

echo "Deploiement des applications ..."
# App1
kubectl apply -f /vagrant/confs/app1/deployment.yaml
kubectl apply -f /vagrant/confs/app1/configMap.yaml
kubectl apply -f /vagrant/confs/app1/service.yaml
# App2
kubectl apply -f /vagrant/confs/app2/deployment.yaml
kubectl apply -f /vagrant/confs/app2/configMap.yaml
kubectl apply -f /vagrant/confs/app2/service.yaml
# App3
kubectl apply -f /vagrant/confs/app3/deployment.yaml
kubectl apply -f /vagrant/confs/app3/configMap.yaml
kubectl apply -f /vagrant/confs/app3/service.yaml
# Ingress
kubectl apply -f /vagrant/confs/ingress.yaml

echo "Verification des deploiements ..."
kubectl get deployments -A
kubectl get pods -A
kubectl get ingress -A

echo "Les deploiements sont un succes !"


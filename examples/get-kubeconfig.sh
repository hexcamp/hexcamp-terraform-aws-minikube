#! /bin/bash

scp centos@minikube1.localnet.farm:/home/centos/kubeconfig_ip .
perl -pi -e 's/kubernetes/minikube1/g' kubeconfig_ip
perl -pi -e 's/admin@//g' kubeconfig_ip
perl -pi -e 's/admin/admin_minikube1/g' kubeconfig_ip
./flatten.sh > kubeconfig2
kubectl --kubeconfig ./kubeconfig2 get node

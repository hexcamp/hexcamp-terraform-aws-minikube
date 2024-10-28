#! /bin/bash

CLUSTER=$(pwd | sed 's,^.*\/,,')

scp centos@$CLUSTER.localnet.farm:/home/centos/kubeconfig_ip .
perl -pi -e "s/kubernetes/$CLUSTER/g" kubeconfig_ip
perl -pi -e 's/admin@//g' kubeconfig_ip
perl -pi -e "s/admin/admin_$CLUSTER/g" kubeconfig_ip
./flatten.sh > kubeconfig2
kubectl --kubeconfig ./kubeconfig2 get node

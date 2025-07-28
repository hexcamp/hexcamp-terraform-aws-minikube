#! /bin/bash

CLUSTER=$(pwd | sed 's,^.*\/,,')

scp ubuntu@$CLUSTER.localnet.farm:/home/ubuntu/kubeconfig kubeconfig_dns
perl -pi -e "s/kubernetes/$CLUSTER/g" kubeconfig_dns
perl -pi -e 's/admin@//g' kubeconfig_dns
perl -pi -e "s/admin/admin_$CLUSTER/g" kubeconfig_dns
./flatten.sh > kubeconfig2
kubectl --kubeconfig ./kubeconfig2 get node -o wide
cp -v ~/.kube/config ~/.kube/config.$(date '+%Y%m%d-%H%M%S')
cp -v ./kubeconfig2 ~/.kube/config

echo argocd cluster rm $CLUSTER -y
echo argocd cluster add $CLUSTER -y

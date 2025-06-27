#! /bin/bash

export KUBECONFIG=kubeconfig_dns:$HOME/.kube/config
kubectl config view --flatten

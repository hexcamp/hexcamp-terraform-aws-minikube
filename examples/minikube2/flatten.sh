#! /bin/bash

export KUBECONFIG=kubeconfig_ip:$HOME/.kube/config
kubectl config view --flatten

#! /bin/bash

export KUBECONFIG=$HOME/.kube/config:kubeconfig_ip
kubectl config view --flatten

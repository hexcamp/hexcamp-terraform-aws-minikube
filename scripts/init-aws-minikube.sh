#!/bin/bash

exec &> /var/log/init-aws-minikube.log

set -o verbose
set -o errexit
set -o pipefail

export KUBEADM_TOKEN=${kubeadm_token}
export DNS_NAME=${dns_name}
export CLUSTER_NAME=${cluster_name}
export ADDONS="${addons}"
export KUBERNETES_VERSION="${kubernetes_version}"

# Set this only after setting the defaults
set -o nounset

# We needed to match the hostname expected by kubeadm an the hostname used by kubelet
TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
LOCAL_IP_ADDRESS=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/local-ipv4)
PUBLIC_IP_ADDRESS=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/public-ipv4)
FULL_HOSTNAME=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/hostname)

echo TOKEN: $TOKEN
echo LOCAL_IP_ADDRESS $LOCAL_IP_ADDRESS
echo PUBLIC_IP_ADDRESS $PUBLIC_IP_ADDRESS
echo FULL_HOSTNAME: $FULL_HOSTNAME

# Make DNS lowercase
DNS_NAME=$(echo "$DNS_NAME" | tr 'A-Z' 'a-z')

# Ubuntu instructions
# https://www.linuxtechi.com/how-to-install-minikube-on-ubuntu/

apt-get update
apt-get upgrade -y


########################################
########################################
# Initialize the Kube cluster
########################################
########################################

# Initialize the master
cat >/tmp/kubeadm.yaml <<EOF
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
bootstrapTokens:
  - groups:
      - system:bootstrappers:kubeadm:default-node-token
    token: $KUBEADM_TOKEN
    ttl: 0s
    usages:
      - signing
      - authentication
nodeRegistration:
  criSocket: unix:///var/run/containerd/containerd.sock
  imagePullPolicy: IfNotPresent
  kubeletExtraArgs:
    cloud-provider: external
    read-only-port: "10255"
  name: $FULL_HOSTNAME
  taints:
    - effect: NoSchedule
      key: node-role.kubernetes.io/master
localAPIEndpoint:
  advertiseAddress: $LOCAL_IP_ADDRESS
  bindPort: 6443
patches:
  directory: /kubeadm-patches
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
apiServer:
  certSANs:
    - $DNS_NAME
    - $PUBLIC_IP_ADDRESS
    - $LOCAL_IP_ADDRESS
    - $FULL_HOSTNAME
  extraArgs:
    cloud-provider: external
  timeoutForControlPlane: 5m0s
certificatesDir: /etc/kubernetes/pki
clusterName: kubernetes
controllerManager:
  extraArgs:
    cloud-provider: external
dns: {}
etcd:
  local:
    dataDir: /var/lib/etcd
kubernetesVersion: v$KUBERNETES_VERSION
networking:
  dnsDomain: cluster.local
  podSubnet: 192.168.0.0/16
  serviceSubnet: 10.96.0.0/12
scheduler: {}
---
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
cgroupDriver: systemd
---
EOF

# https://serverfault.com/questions/1089688/setting-resource-limits-on-kube-apiserver
# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/control-plane-flags/#patches
mkdir -p /kubeadm-patches
cat >/kubeadm-patches/etcd.yaml <<EOF
spec:
  containers:
  - name: etcd
    resources:
      \$patch: delete
EOF
cat >/kubeadm-patches/kube-apiserver.yaml <<EOF
spec:
  containers:
  - name: kube-apiserver
    resources:
      \$patch: delete
EOF
cat >/kubeadm-patches/kube-controller-manager.yaml <<EOF
spec:
  containers:
  - name: kube-controller-manager
    resources:
      \$patch: delete
EOF
cat >/kubeadm-patches/kube-scheduler.yaml <<EOF
spec:
  containers:
  - name: kube-scheduler
    resources:
      \$patch: delete
EOF

kubeadm reset --force
kubeadm init --config /tmp/kubeadm.yaml --ignore-preflight-errors=NumCPU

# Use the local kubectl config for further kubectl operations
export KUBECONFIG=/etc/kubernetes/admin.conf


# Install calico
kubectl create -f https://raw.githubusercontent.com/scholzj/terraform-aws-minikube/master/calico/calico-operator.yaml
kubectl create -f https://raw.githubusercontent.com/scholzj/terraform-aws-minikube/master/calico/calico-cr.yaml

# Instal AWS Cloud Provider
kubectl create -f https://raw.githubusercontent.com/hexcamp/hexcamp-terraform-aws-minikube/refs/heads/ubuntu/aws-cloud-provider/aws-cloud-provider.yaml

# Wait for the AWS Cloud Provider to be running
while [[ $(kubectl get pod -l k8s-app=aws-cloud-controller-manager -n kube-system -o name | wc -c) -eq 0 ]]; do
   echo "Waiting for cloud manager"
   sleep 1
done

AWS_CLOUD_PROVIDER_POD=$(kubectl get pod -l k8s-app=aws-cloud-controller-manager -n kube-system -o name)
kubectl wait $AWS_CLOUD_PROVIDER_POD -n kube-system --for=condition=Ready --timeout=300s

# Allow all apps to run on master
kubectl taint nodes --all node-role.kubernetes.io/master-

# Allow load balancers to route to master
kubectl label nodes --all node-role.kubernetes.io/master-

# Allow loadbalancers to route to master nodes
kubectl label nodes --all node.kubernetes.io/exclude-from-external-load-balancers-

########################################
########################################
# Create user and kubeconfig files
########################################
########################################

# Allow the user to administer the cluster
kubectl create clusterrolebinding admin-cluster-binding --clusterrole=cluster-admin --user=admin

# Prepare the kubectl config file for download to client (IP address)
export KUBECONFIG_OUTPUT=/home/ubuntu/kubeconfig_ip
kubeadm kubeconfig user --client-name admin --config /tmp/kubeadm.yaml > $KUBECONFIG_OUTPUT
chown ubuntu:ubuntu $KUBECONFIG_OUTPUT
chmod 0600 $KUBECONFIG_OUTPUT

cp /home/ubuntu/kubeconfig_ip /home/ubuntu/kubeconfig
sed -i "s/server: https:\/\/.*:6443/server: https:\/\/$PUBLIC_IP_ADDRESS:6443/g" /home/ubuntu/kubeconfig_ip
sed -i "s/server: https:\/\/.*:6443/server: https:\/\/$DNS_NAME:6443/g" /home/ubuntu/kubeconfig
chown ubuntu:ubuntu /home/ubuntu/kubeconfig
chmod 0600 /home/ubuntu/kubeconfig

########################################
########################################
# Install addons
########################################
########################################
for ADDON in $ADDONS
do
  curl $ADDON | envsubst > /tmp/addon.yaml
  kubectl apply -f /tmp/addon.yaml
  rm /tmp/addon.yaml
done

echo Done.

reboot


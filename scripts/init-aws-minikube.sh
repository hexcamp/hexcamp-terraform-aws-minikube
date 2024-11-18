#!/bin/bash

exec &> /var/log/init-aws-minikube.log

set -o verbose
set -o errexit
set -o pipefail

export KUBEADM_TOKEN=${kubeadm_token}
export DNS_NAME=${dns_name}
export IP_ADDRESS=${ip_address}
export CLUSTER_NAME=${cluster_name}
export ADDONS="${addons}"
export KUBERNETES_VERSION="${kubernetes_version}"

# Set this only after setting the defaults
set -o nounset

# We needed to match the hostname expected by kubeadm an the hostname used by kubelet
TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
LOCAL_IP_ADDRESS=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/local-ipv4)
FULL_HOSTNAME=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/hostname)

# Make DNS lowercase
DNS_NAME=$(echo "$DNS_NAME" | tr 'A-Z' 'a-z')

# Ubuntu instructions
# https://www.linuxtechi.com/how-to-install-minikube-on-ubuntu/

apt-get update
apt-get upgrade -y
apt-get install -y curl wget apt-transport-https ca-certificates \
	docker.io

# https://minikube.sigs.k8s.io/docs/start/?arch=%2Flinux%2Fx86-64%2Fstable%2Fdebian+package

curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube_latest_amd64.deb
sudo dpkg -i minikube_latest_amd64.deb

adduser ubuntu docker

# https://joepreludian.medium.com/how-to-start-up-minikube-automatically-via-system-d-2cad99fd79bf

cat <<EOF | tee /etc/systemd/system/minikube.service
[Unit]
Description=Kickoff Minikube Cluster
After=docker.service

[Service]
Type=oneshot
ExecStart=/usr/bin/minikube start
RemainAfterExit=true
ExecStop=/usr/bin/minikube stop
StandardOutput=journal
User=ubuntu
Group=ubuntu

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable minikube
systemctl start minikube

curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
chmod +x kubectl
mv kubectl /usr/local/bin/


exit 0

cd /tmp
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
install minikube-linux-amd64 /usr/local/bin/minikube
minikube version

curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl
chmod +x kubectl
mv kubectl /usr/local/bin/
#kubectl version -o yaml

# Docker

# https://www.linuxtechi.com/install-docker-on-ubuntu-24-04/

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update
apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

usermod -aG docker ubuntu
newgrp docker
docker --version

systemctl status docker


########################################
########################################
# Disable SELinux
########################################
########################################
#setenforce 0
#sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/sysconfig/selinux
#sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config

########################################
########################################
# Install containerd
########################################
########################################
#cat <<EOF | tee /etc/modules-load.d/containerd.conf
#overlay
#br_netfilter
#EOF

#modprobe overlay
#modprobe br_netfilter

# Setup required sysctl params, these persist across reboots.
#cat <<EOF | tee /etc/sysctl.d/99-kubernetes-cri.conf
#net.bridge.bridge-nf-call-iptables  = 1
#net.ipv4.ip_forward                 = 1
#net.bridge.bridge-nf-call-ip6tables = 1
#EOF

# Apply sysctl params without reboot
#sysctl --system

# https://serverfault.com/questions/1161816/mirrorlist-centos-org-no-longer-resolve
#sed -i s/mirror.centos.org/vault.centos.org/g /etc/yum.repos.d/CentOS-*.repo
#sed -i s/^#.*baseurl=http/baseurl=http/g /etc/yum.repos.d/CentOS-*.repo
#sed -i s/^mirrorlist=http/#mirrorlist=http/g /etc/yum.repos.d/CentOS-*.repo
#yum update -y


#yum install -y yum-utils curl gettext device-mapper-persistent-data lvm2
#yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
#sudo yum install -y containerd.io
#mkdir -p /etc/containerd
#containerd config default > /etc/containerd/config.toml
#sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
#systemctl restart containerd
#systemctl enable containerd

########################################
########################################
# Install Kubernetes components
########################################
########################################
#sudo cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
#[kubernetes]
#name=Kubernetes
#baseurl=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/
#enabled=1
#gpgcheck=1
#gpgkey=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/repodata/repomd.xml.key
#exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
#EOF

#yum install -y kubectl kubelet-$KUBERNETES_VERSION kubeadm-$KUBERNETES_VERSION kubernetes-cni --disableexcludes=kubernetes

# Start services
#systemctl enable kubelet
#systemctl start kubelet

exit 0

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
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
apiServer:
  certSANs:
    - $DNS_NAME
    - $IP_ADDRESS
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

kubeadm reset --force
kubeadm init --config /tmp/kubeadm.yaml

# Use the local kubectl config for further kubectl operations
export KUBECONFIG=/etc/kubernetes/admin.conf

# Install calico
kubectl create -f https://raw.githubusercontent.com/scholzj/terraform-aws-minikube/master/calico/calico-operator.yaml
kubectl create -f https://raw.githubusercontent.com/scholzj/terraform-aws-minikube/master/calico/calico-cr.yaml

# Instal AWS Cloud Provider
kubectl create -f https://raw.githubusercontent.com/scholzj/terraform-aws-minikube/master/aws-cloud-provider/aws-cloud-provider.yaml

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
export KUBECONFIG_OUTPUT=/home/centos/kubeconfig_ip
kubeadm kubeconfig user --client-name admin --config /tmp/kubeadm.yaml > $KUBECONFIG_OUTPUT
chown centos:centos $KUBECONFIG_OUTPUT
chmod 0600 $KUBECONFIG_OUTPUT

cp /home/centos/kubeconfig_ip /home/centos/kubeconfig
sed -i "s/server: https:\/\/.*:6443/server: https:\/\/$IP_ADDRESS:6443/g" /home/centos/kubeconfig_ip
sed -i "s/server: https:\/\/.*:6443/server: https:\/\/$DNS_NAME:6443/g" /home/centos/kubeconfig
chown centos:centos /home/centos/kubeconfig
chmod 0600 /home/centos/kubeconfig

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

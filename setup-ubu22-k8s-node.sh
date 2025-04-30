#!/bin/bash
#set -x
#Usage: $ setup-ubu22-k8s-node.sh node-type
#Eg:    $ setup-ubu22-k8s-node-sh master-node
#Targeted at a base build of Ubuntu Server 22.04
#Setup is for Kubernetes nodes, choose master-node or worker node
#deploys with Kubernetes version 1.30 wth Docker and flannel network plugin.
#

#Update and install base bpackages to get going
sudo apt update
sudo apt-get install -y apt-transport-https ca-certificates curl

# Setup Docker
sudo apt install docker.io -y
sudo systemctl enable docker
sudo systemctl status docker
sudo systemctl start docker

# Seup kubernetes
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Install kubernetes tools
#sync; sync; sync; sleep 60
echo "========= INSTALING KUBERNETES TOOLS NOW ========="
sudo apt update
sudo apt install conntrack cri-tools kubeadm kubectl kubelet kubernetes-cni -y
sudo apt-mark hold kubeadm kubelet kubectl
kubeadm version

# Turn off and disable swap
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Turn off the firewall
sudo systemctl stop ufw
sudo systemctl disable ufw
sudo systemctl status ufw

# Setup containerd - has to be done even though we are using Docker, it needs this package
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
sudo sed -i 's/registry.k8s.io\/pause:3.8/registry.k8s.io\/pause:3.9/g' /etc/containerd/config.toml
sudo sed -i '/containerd.runtimes.runc]/a\          SystemdCgroup = true' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd
sudo systemctl status containerd

# Configure for Kubernetes networking

echo "overlay"      | sudo tee -a /etc/modules-load.d/containerd.conf
echo "br_netfilter" | sudo tee -a /etc/modules-load.d/containerd.conf
sudo modprobe overlay
sudo modprobe br_netfilter
echo "net.bridge.bridge-nf-call-ip6tables = 1" | sudo tee -a /etc/sysctl.d/kubernetes.conf
echo "net.bridge.bridge-nf-call-iptables = 1"  | sudo tee -a /etc/sysctl.d/kubernetes.conf
echo "net.ipv4.ip_forward = 1"                 | sudo tee -a /etc/sysctl.d/kubernetes.conf
sudo sysctl --system

# Initialize kubernetes on controller node
echo "KUBELET_EXTRA_ARGS="--cgroup-driver=cgroupfs"" | sudo tee -a /etc/default/kubelet
sudo systemctl daemon-reload && sudo systemctl restart kubelet

# Append config block
my_driver=$(cat <<EOF
{
      "exec-opts": ["native.cgroupdriver=systemd"],
      "log-driver": "json-file",
      "log-opts": {
      "max-size": "100m"
   },
       "storage-driver": "overlay2"
       }
EOF
)
echo "$my_driver" | sudo tee -a /etc/docker/daemon.json
sudo systemctl daemon-reload && sudo systemctl restart docker
sudo mkdir -p /etc/systemd/system/kubelet.service.d
#sudo touch /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
#echo "Environment="KUBELET_EXTRA_ARGS=--fail-swap-on=false"" | sudo tee -a /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
#sudo systemctl daemon-reload && sudo systemctl restart kubelet

# Initialize the Kubernetes cluster
set -x
if [ $1 == "master-node" ]; then
  echo "========= INITIALIZING KUBERNETES CLUSTER NOW ========="
  #sudo systemctl stop kubelet
  sudo kubeadm init --control-plane-endpoint=master-node --upload-certs --pod-network-cidr=10.244.0.0/16

  # Setup for the user
  sudo mkdir -p /home/ubuadmin/.kube
  sudo cp /etc/kubernetes/admin.conf /home/ubuadmin/.kube/config
  #sudo chown $(id -u):$(id -g) $HOME/.kube/config
  sudo chown -R ubuadmin:ubuadmin /home/ubuadmin/.kube

  # Deploy POD network
  kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
  kubectl taint nodes --all node-role.kubernetes.io/control-plane-
  kubectl get nodes -o wide
  kubectl get all --all-namespaces
fi

#Final update/upgrade
sudo apt update
sudo DEBIAN_FRONTEND=noninteractive apt -yq upgrade

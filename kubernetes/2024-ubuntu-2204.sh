#!/bin/bash

# set timezone
timedatectl set-timezone Asia/Seoul

# manage swap memory
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# load kernel modules
sudo tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter

# update ipatable parameter
sudo tee /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system

# install packages
sudo apt-get install -y curl gnupg2 \
  software-properties-common \
  apt-transport-https \
  ca-certificates

# add docker apt repository
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmour -o /etc/apt/trusted.gpg.d/docker.gpg
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

sudo apt-get update
sudo apt-get install -y containerd.io

# set up containerd
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1
sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml

# run containerd
sudo systemctl restart containerd
sudo systemctl enable containerd

# add k8s apt repository
sudo curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/dev/Release.key | sudo gpg --dearmour -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# install kubernetes
sudo apt-get update
sudo apt-get install -y kubectl kubeadm kubelet

# install bash-completion
sudo apt-get install -y bash-completion

echo "source <(kubectl completion bash)>" >> ~/.bashrc
echo "alias k = kubectl" >> ~/.bashrc
echo "complete -o default -F __start_kubectl k" >> ~/.bashrc

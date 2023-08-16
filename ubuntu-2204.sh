#!/bin/bash

# off swap memory
sudo swapoff -a

# update fstab file, adding # on swapfile
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# load kernel modules

sudo tee /etc/module-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter

# set kernel parameter
sudo tee /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

sudo sysctl --system


# install necessary packages
sudo apt-get install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates

# add docker repository to system
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmour -o /etc/apt/trusted.gpg.d/docker.gpg
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# install containerd
sudo apt-get update
sudo apt-get install -y containerd.io

# configure containerd
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1
sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml

# restart & enable containerd service
sudo systemctl restart containerd
sudo systemctl enable containerd

# add kubernetes repository to system
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmour -o /etc/apt/trusted.gpg.d/kubernetes-xenial.gpg
sudo apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"

# install kubectl, kubeadm, kubelet
sudo apt-get update
sudo apt-get install -y kubectl kubeadm kubelet
sudo apt-mark hold kubectl kubeadm kubelet

# initialize kubernetes
sudo kubeadm init | tee $HOME/init.txt

# make config directory to normal user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# check master node is running
kubectl cluster-info
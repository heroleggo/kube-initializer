sudo kubeadm init | tee $HOME/init.txt

mkdir -p $HOME/.kube
sudo cp -io /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

kubectl cluster-info

kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifest/calico.yaml
kubeadm token create --print-join-command
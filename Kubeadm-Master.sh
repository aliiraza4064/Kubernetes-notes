# first of all do swapoff
sudo swapoff -a
            
            # Forwarding IPv4 and letting iptables see bridged traffic

            
# Execute the below mentioned instructions:
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward
# ---------------------------------------------------------------------------

                # Installing kubeadm:


# Update the apt package index and install packages needed to use the Kubernetes apt repository:
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl
# Create directory for keyrings
mkdir /etc/apt/keyrings
# Download the Google Cloud public signing key:
sudo curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://dl.k8s.io/apt/doc/apt-key.gpg
# Add the Kubernetes apt repository:
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
# Update apt package index, install kubelet, kubeadm and kubectl, and pin their version:
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl docker.io
sudo apt-mark hold kubelet kubeadm kubectl docker.io

# Note: In releases older than Debian 12 and Ubuntu 22.04, /etc/apt/keyrings does not exist by default. You can create this directory if you need to, making it world-readable but writeable only by admins.
# ---------------------------------------------------------------------------

                #  Init kubeadm


sudo kubeadm init --pod-network-cidr 192.168.0.0/16
# To start using your cluster, you need to run the following as a regular user:
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
# Alternatively, if you are the root user, you can run:
export KUBECONFIG=/etc/kubernetes/admin.conf
# ---------------------------------------------------------------------------

              # Install Calico:


# First, install the operator on your cluster.
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.1/manifests/tigera-operator.yaml
# Download the custom resources necessary to configure Calico
curl https://raw.githubusercontent.com/projectcalico/calico/v3.25.1/manifests/custom-resources.yaml -O

# If you wish to customize the Calico install, customize the downloaded custom-resources.yaml manifest locally.
# Create the manifest in order to install Calico.
kubectl create -f custom-resources.yaml


# Delete Evicted or status unknown:
# kubectl get pod -n tigera-operator | grep ContainerStatusUnknown | awk '{print $1}' | xargs kubectl delete pod -n tigera-operator

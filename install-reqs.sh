#!/bin/bash
#
# Description: This script is designed to deploy the 5G testbed at UWaterloo.
# Author: Niloy Saha
# Modified: Shayan Mohammadi Kubijari
# Date: 14/03/2024
# Usage: Please ensure that you run this script as ROOT or with ROOT permissions.
# Notes: This script is designed for use with Ubuntu 22.04.
# ==============================================================================

DOCKER_VERSION="5:20.10.24~3-0~ubuntu-jammy"
KUBE_VERSION_SHORT="1.28"
KUBE_VERSION_FULL="1.28.6-1.1"
HELM_VERSION="3.13.1-1"

cecho() {
  case "$1" in
  "RED") color="\033[0;31m" ;;
  "GREEN") color="\033[0;32m" ;;
  "YELLOW") color="\033[0;33m" ;;
  *) color="\033[0m" ;; # No Color
  esac
  echo -e "${color}$2\033[0m"
}

run-as-root() {
  if [ "$EUID" -ne 0 ]; then
    cecho "RED" "This script must be run as ROOT"
    exit
  fi
}

install-packages() {
  sudo apt update
  sudo apt install -y vim tmux git curl ca-certificates apt-transport-https gpg net-tools iproute2 iputils-ping iperf3 tcpdump python3-pip
  sudo pip3 install virtualenv
}

disable-swap() {
  cecho "GREEN" "Disabling swap ..."
  sudo swapoff -a
  sudo sed -i '/swap/ s/^/#/' /etc/fstab
}

disable-firewall() {
  cecho "YELLOW" "Disabling firewall ..."
  sudo ufw disable
}

install-docker() {
  if [ -x "$(command -v docker)" ]; then
    cecho "YELLOW" "Docker is already installed."
  else
    cecho "GREEN" "Installing Docker..."
    sudo apt purge -y docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
    sudo apt update
    sudo apt install -y docker-ce=$DOCKER_VERSION docker-ce-cli=$DOCKER_VERSION containerd.io docker-buildx-plugin docker-compose-plugin
    sudo apt-mark hold docker-ce docker-ce-cli
    sudo mkdir -p /etc/containerd
    sudo bash -c 'containerd config default > /etc/containerd/config.toml'
    sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
    sudo groupadd docker
    sudo usermod -aG docker $USER
    mkdir -p /etc/systemd/system/docker.service.d/
    cat > /etc/systemd/system/docker.service.d/docker.conf << EOF
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd -H fd:// --insecure-registry=nexus3.onap.org:10001
EOF
    sudo systemctl enable --now containerd
    sudo systemctl enable --now docker
    systemctl daemon-reload
    sudo systemctl restart containerd
    sudo systemctl restart docker
    docker login -u docker -p docker nexus3.onap.org:10001
    sudo docker run hello-world
    if sudo systemctl is-active docker &>/dev/null; then
      cecho "GREEN" "Docker is running :)"
    else
      cecho "RED" "Docker installation failed or is not running :("
    fi
  fi
}

setup-k8s-networking() {
  cecho "GREEN" "Setting up Kubernetes networking ..."
  cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
  sudo modprobe overlay
  sudo modprobe br_netfilter
  cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
  sudo sysctl --system >/dev/null
}

install-k8s() {
  if [ -x "$(command -v kubectl)" ] && [ -x "$(command -v kubeadm)" ] && [ -x "$(command -v kubelet)" ]; then
    cecho "YELLOW" "Kubernetes components (kubectl, kubeadm, kubelet) are already installed."
  else
    cecho "GREEN" "Installing Kubernetes components (kubectl, kubeadm, kubelet) ..."
    sudo apt update
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v${KUBE_VERSION_SHORT}/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v'"${KUBE_VERSION_SHORT}"'/deb/ /' |
      sudo tee /etc/apt/sources.list.d/kubernetes.list
    sudo apt update
    sudo apt install -y kubelet=${KUBE_VERSION_FULL} kubeadm=${KUBE_VERSION_FULL} kubectl=${KUBE_VERSION_FULL}
    sudo apt-mark hold kubelet kubeadm kubectl
  fi
}

install-helm() {
  CUR_VERSION=$(helm version --short 2>/dev/null)
  if [[ "${CUR_VERSION}" != *"3"* ]]; then
    cecho "GREEN" "Helm 3 is not installed. Proceeding to install Helm ..."
    curl -s https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg >/dev/null
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
    sudo apt update
    sudo apt install helm=${HELM_VERSION}
    sudo apt-mark hold helm
  else
    cecho "YELLOW" "Helm 3 is already installed."
  fi
}

# Run installation steps
run-as-root
install-packages
disable-swap
disable-firewall
setup-k8s-networking
install-docker
install-k8s
install-helm

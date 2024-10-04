#!/bin/bash
#
# Description: This script is designed to deploy the 5G testbed at UWaterloo.
# Author: Niloy Saha
# Modified: Shayan Mohammadi Kubijari
# Date: 14/03/2024
# Usage: Please ensure that you run this script as ROOT or with ROOT permissions.
# Notes: This script is designed for use with Ubuntu 22.04.
# ==============================================================================

# Function to display messages in different colors
cecho() {
  case "$1" in
  "RED") color="\033[0;31m" ;;
  "GREEN") color="\033[0;32m" ;;
  "YELLOW") color="\033[0;33m" ;;
  *) color="\033[0m" ;; # No Color
  esac
  echo -e "${color}$2\033[0m"
}

# Check if the script is run as root, exit if not
run-as-root() {
  if [ "$EUID" -ne 0 ]; then
    cecho "RED" "This script must be run as ROOT"
    exit 1
  fi
}

# Timer function for delaying script execution
timer-sec() {
  secs=$((${1}))
  while [ $secs -gt 0 ]; do
    echo -ne "Waiting for $secs\033[0K seconds ...\r"
    sleep 1
    : $((secs--))
  done
}

# Function to create Kubernetes cluster
create-k8s-cluster() {
  if [ -f "/etc/kubernetes/admin.conf" ]; then
    cecho "YELLOW" "A Kubernetes cluster already exists. Skipping cluster creation."
  else
    cecho "GREEN" "Creating k8s cluster ..."
    sudo kubeadm init --config config-kubeadm.yaml

    # Setup kubectl without sudo
    mkdir -p ${HOME}/.kube
    sudo cp -i /etc/kubernetes/admin.conf ${HOME}/.kube/config
    sudo chown $(id -u):$(id -g) ${HOME}/.kube/config

    timer-sec 60
    cecho "YELLOW" "Waiting 60 secs for cluster to be ready"
    kubectl taint nodes --all node-role.kubernetes.io/control-plane:NoSchedule- || true
  fi
}

# Function to install Flannel CNI
install-cni() {
  if ! kubectl get pods -n kube-flannel -l app=flannel | grep -q '1/1'; then
    cecho "GREEN" "Installing Flannel as primary CNI ..."
    kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
    timer-sec 60
    kubectl wait pods -n kube-flannel -l app=flannel --for condition=Ready --timeout=120s
  fi
}

# Function to install Multus CNI
install-multus() {
  if ! kubectl get pods -n kube-system -l app=multus | grep -q '1/1'; then
    cecho "GREEN" "Installing Multus as meta CNI ..."
    if [ ! -d "build/multus-cni" ]; then
      git clone https://github.com/k8snetworkplumbingwg/multus-cni.git build/multus-cni
    else
      git -C build/multus-cni pull
    fi
    cd build/multus-cni
    kubectl apply -f ./deployments/multus-daemonset-thick.yml
    cd ..
    timer-sec 30
    kubectl wait pods -n kube-system -l app=multus --for condition=Ready --timeout=120s
  fi
}

# Function to install OpenEBS
install-openebs() {
  if ! kubectl get pods -n openebs -l app=openebs | grep -q '1/1'; then
    cecho "GREEN" "Installing OpenEBS for storage management ..."
    helm repo add openebs https://openebs.github.io/charts
    helm repo update
    helm upgrade --install openebs --namespace openebs openebs/openebs --create-namespace
    kubectl patch storageclass openebs-hostpath -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
  fi
}

# Function to setup and install OVS CNI
setup-ovs-cni() {
  if ! command -v ovs-vsctl &>/dev/null; then
    cecho "GREEN" "Installing OpenVSwitch ..."
    sudo apt update
    sudo apt install -y openvswitch-switch
  fi
  cecho "GREEN" "Configuring bridges for use by ovs-cni ..."
  sudo ovs-vsctl --may-exist add-br n2br
  sudo ovs-vsctl --may-exist add-br n3br
  sudo ovs-vsctl --may-exist add-br n4br

  cecho "GREEN" "Installing ovs-cni ..."
  kubectl apply -f https://github.com/kubevirt/cluster-network-addons-operator/releases/download/v0.89.1/namespace.yaml
  kubectl apply -f https://github.com/kubevirt/cluster-network-addons-operator/releases/download/v0.89.1/network-addons-config.crd.yaml
  kubectl apply -f https://github.com/kubevirt/cluster-network-addons-operator/releases/download/v0.89.1/operator.yaml
  kubectl apply -f https://gist.githubusercontent.com/niloysh/1f14c473ebc08a18c4b520a868042026/raw/d96f07e241bb18d2f3863423a375510a395be253/network-addons-config.yaml
  timer-sec 30
  kubectl wait networkaddonsconfig cluster --for condition=Available
}

# Ensure script is run as root
run-as-root

# Execute cluster creation and component installations
create-k8s-cluster
install-cni
install-multus
install-openebs
setup-ovs-cni

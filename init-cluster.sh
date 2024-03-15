#!/bin/bash
#
# Description: This script is designed to deploy the 5G testbed at UWaterloo.
# Author: Niloy Saha
# Date: 24/10/2023
# Version: 1.0
# Usage: Please ensure that you run this script as ROOT or with ROOT permissions.
# Notes: This script is designed for use with Ubuntu 22.04.
# ==============================================================================

# Modified: Shayan Mohammadi Kubijari
# Date: 14/03/2024
# Reason: Separate files for starting a cluster and installing prereq software (k8s, docker, helm, ...)

create-k8s-cluster() {
  if [ -f "/etc/kubernetes/admin.conf" ]; then
    cecho "YELLOW" "A Kubernetes cluster already exists. Skipping cluster creation."
  else
    cecho "GREEN" "Creating k8s cluster ..."
    sudo kubeadm init --config kubeadm-config.yaml

    # Setup kubectl without sudo
    mkdir -p ${HOME}/.kube
    sudo cp -i /etc/kubernetes/admin.conf ${HOME}/.kube/config
    sudo chown $(id -u):$(id -g) ${HOME}/.kube/config

    timer=60
    cecho "YELLOW" "Waiting $timer secs for cluster to be ready"
    timer-sec $timer

    # Remove NoSchedule taint from all nodes
    cecho "GREEN" "Allowing scheduling pods on master node ..."
    kubectl taint nodes --all node-role.kubernetes.io/control-plane:NoSchedule-
  fi
}

# Install Flannel as CNI
install-cni() {
  if kubectl get pods -n kube-flannel -l app=flannel | grep -q '1/1'; then
    cecho "YELLOW" "Flannel is already running. Skipping installation."
  else
    cecho "GREEN" "Installing Flannel as primary CNI ..."
    kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
    timer-sec 60
    kubectl wait pods -n kube-flannel  -l app=flannel --for condition=Ready --timeout=120s
  fi
}

# Install Multus as meta CNI
install-multus() {
  if kubectl get pods -n kube-system -l app=multus | grep -q '1/1'; then
    cecho "YELLOW" "Multus is already running. Skipping installation."
  else
    cecho "GREEN" "Installing Multus as meta CNI ..."
    git -C build/multus-cni pull || git clone https://github.com/k8snetworkplumbingwg/multus-cni.git build/multus-cni
    cd build/multus-cni
    cat ./deployments/multus-daemonset-thick.yml | kubectl apply -f -
    timer-sec 30
    kubectl wait pods -n kube-system  -l app=multus --for condition=Ready --timeout=120s
  fi
}

install-openebs() {
  if kubectl get pods -n openebs -l app=openebs | grep -q '1/1'; then
    cecho "YELLOW" "OpenEBS is already running. Skipping installation."
  else
    cecho "GREEN" "Installing OpenEBS for storage management ..."
    helm repo add openebs https://openebs.github.io/charts
    helm repo update
    helm upgrade --install openebs --namespace openebs openebs/openebs --create-namespace

    # patch k8s storageclass to make openebs-hostpath as default
    kubectl patch storageclass openebs-hostpath -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
  fi
}

setup-ovs-cni() {
  if [ -x "$(command -v ovs-vsctl)" ]; then
    cecho "YELLOW" "OpenVSwitch is already installed."
  else
    cecho "GREEN" "Installing OpenVSwitch ..."
    sudo apt-get update
    sudo apt-get install openvswitch-switch
  fi

  cecho "GREEN" "Configuring bridges for use by ovs-cni ..."
  sudo ovs-vsctl --may-exist add-br n2br
  sudo ovs-vsctl --may-exist add-br n3br
  sudo ovs-vsctl --may-exist add-br n4br

  # install ovs-cni
  # install cluster-network-addons operator
  cecho "GREEN" "Installing ovs-cni ..."

  kubectl apply -f https://github.com/kubevirt/cluster-network-addons-operator/releases/download/v0.89.1/namespace.yaml
  kubectl apply -f https://github.com/kubevirt/cluster-network-addons-operator/releases/download/v0.89.1/network-addons-config.crd.yaml 
  kubectl apply -f https://github.com/kubevirt/cluster-network-addons-operator/releases/download/v0.89.1/operator.yaml

  kubectl apply -f https://gist.githubusercontent.com/niloysh/1f14c473ebc08a18c4b520a868042026/raw/d96f07e241bb18d2f3863423a375510a395be253/network-addons-config.yaml
  
  timer-sec 30
  kubectl wait networkaddonsconfig cluster --for condition=Available


}

# ./install.sh
create-k8s-cluster
install-cni
install-multus
install-openebs
setup-ovs-cni

#!/bin/bash
#
# Description: This script cleans up the k8s cluster deployed using init-cluster.sh
# Author: Niloy Saha 			(version 1.0)
# 	  Shayan Mohammadi Kubijari	(version 1.1)
# Last Mod Date: 2024/06/08
# Usage: Please ensure that you run this script as ROOT or with ROOT permissions.
# Notes: This script is designed for use with Ubuntu 22.04.
# ==============================================================================

run-as-root() {
  if [ "$EUID" -ne 0 ]; then
    cecho "RED" "This script must be run as ROOT"
    exit
  fi
}

timer-sec() {
  secs=$((${1}))
  while [ $secs -gt 0 ]; do
    echo -ne "Waiting for $secs\033[0K seconds ...\r"
    sleep 1
    : $((secs--))
  done
}

# Based on https://stackoverflow.com/a/53463162/9346339
cecho() {
  RED="\033[0;31m"
  GREEN="\033[0;32m"  # <-- [0 means not bold
  YELLOW="\033[1;33m" # <-- [1 means bold
  CYAN="\033[1;36m"
  # ... Add more colors if you like

  NC="\033[0m" # No Color

  # printf "${(P)1}${2} ${NC}\n" # <-- zsh
  printf "${!1}${2} ${NC}\n" # <-- bash
}

reset_k8s_cluster() {
  cecho "RED" "Deleting Kubernetes cluster..."
  if [ -f "/etc/kubernetes/admin.conf" ]; then
    sudo kubeadm reset -f -q
    cecho "GREEN" "Kubernetes cluster has been deleted."
  else
    cecho "YELLOW" "Kubernetes cluster is not running."
  fi

  sudo rm -rf ${HOME}/.kube /etc/kubernetes /var/lib/kubelet /var/run/kubernetes
  sudo rm -rf /var/lib/etcd /var/lib/etcd2
  sudo rm -rf /var/lib/dockershim /var/lib/docker /etc/docker /var/run/docker.sock
  sudo rm -f /etc/apparmor.d/docker /etc/systemd/system/etcd*
}

uninstall_flannel() {
  cecho "RED" "Uninstalling Flannel CNI ..."
  if kubectl get pods -n kube-flannel -l app=flannel | grep -q '1/1'; then
    kubectl delete -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
    cecho "GREEN" "Uninstalled Flannel CNI."
  else
    cecho "YELLOW" "Flannel CNI is not installed."
  fi
  cecho "RED" "Removing CNI configuration files ..."
  sudo rm -rf /etc/cni
}

uninstall_openebs() {
  cecho "RED" "Removing openebs ..."
  if kubectl get namespace | grep -q openebs; then
    helm uninstall openebs -n openebs
    kubectl delete ns openebs
  else
    cecho "YELLOW" "OpenEBS is not installed."
    return
  fi

  cecho "GREEN" "OpenEBS has been uninstalled."
}

uninstall_multus() {
  cecho "RED" "Uninstalling multus ..."
  if kubectl get pods -n kube-system -l app=multus | grep -q '1/1'; then
    kubectl delete -f build/multus-cni/deployments/multus-daemonset-thick.yml
    cecho "GREEN" "Uninstalled multus."
  else
    cecho "YELLOW" "Multus is not installed."
  fi
}

remove_ovs_cni() {
  cecho "RED" "Removing OVS CNI setup..."

  if kubectl get namespace | grep -q cluster-network-addons; then
    cecho "RED" "Removing cluster-network-addons ..."
    kubectl delete -f https://github.com/kubevirt/cluster-network-addons-operator/releases/download/v0.89.1/namespace.yaml
    cecho "GREEN" "OVS CNI has been removed."
  else
    cecho "YELLOW" "OVS CNI is not installed"
  fi

  if [ -x "$(command -v ovs-vsctl)" ]; then
    cecho "RED" "Removing OpenVSwitch"
    sudo apt purge -y openvswitch-switch
    cecho "GREEN" "OpenVSwitch has been removed."
  else
    cecho "YELLOW" "OpenVSwitch is not installed"
  fi
}

cleanup() {
  cecho "RED" "Cleaning up build directories and redundant packages ..."
  sudo rm -rf build
  sudo apt autoremove -y
}

remove_ovs_cni
uninstall_openebs
uninstall_multus
uninstall_flannel
reset_k8s_cluster
cleanup

cecho "GREEN" "Uninstallation completed."

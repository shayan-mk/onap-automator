#!/bin/bash
#
# Description: This script cleans up the k8s cluster deployed using init-cluster.sh
# Author: Niloy Saha (version 1.0)
#        Shayan Mohammadi Kubijari (version 1.1)
# Last Mod Date: 2024/06/08
# Usage: Please ensure that you run this script as ROOT or with ROOT permissions.
# Notes: This script is designed for use with Ubuntu 22.04.
# ==============================================================================

# Function to display colored messages
cecho() {
  case "$1" in
  "RED") color="\033[0;31m" ;;
  "GREEN") color="\033[0;32m" ;;
  "YELLOW") color="\033[0;33m" ;;
  *) color="\033[0m" ;; # No Color
  esac
  echo -e "${color}$2\033[0m"
}

# Ensure the script is run as root
run-as-root() {
  if [ "$EUID" -ne 0 ]; then
    cecho "RED" "This script must be run as ROOT"
    exit 1
  fi
}

# Function to reset the Kubernetes cluster
reset_k8s_cluster() {
  cecho "RED" "Deleting Kubernetes cluster..."
  if [ -f "/etc/kubernetes/admin.conf" ]; then
    sudo kubeadm reset -f -q
    cecho "GREEN" "Kubernetes cluster has been deleted."
    sudo rm -rf ~/.kube /etc/kubernetes /var/lib/kubelet /var/run/kubernetes
    sudo rm -rf /var/lib/etcd /var/lib/etcd2
    sudo rm -rf /var/lib/dockershim
  else
    cecho "YELLOW" "Kubernetes cluster is not running."
  fi
}

# Function to uninstall CNIs
uninstall_cni() {
  cecho "RED" "Uninstalling CNIs..."
  kubectl delete -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
  kubectl delete -f build/multus-cni/deployments/multus-daemonset-thick.yml
  kubectl delete -f https://github.com/kubevirt/cluster-network-addons-operator/releases/download/v0.89.1/namespace.yaml
  sudo rm -rf /etc/cni
  cecho "GREEN" "CNIs uninstalled."
}

# Function to uninstall OpenEBS
uninstall_openebs() {
  cecho "RED" "Removing OpenEBS..."
  if kubectl get namespace | grep -q openebs; then
    helm uninstall openebs -n openebs
    kubectl delete ns openebs
    cecho "GREEN" "OpenEBS has been uninstalled."
  else
    cecho "YELLOW" "OpenEBS is not installed."
  fi
}

# Cleanup function to remove build directories and perform system cleanup
cleanup() {
  cecho "RED" "Cleaning up build directories and redundant packages..."
  sudo rm -rf build
  sudo apt autoremove -y
  cecho "GREEN" "Cleanup complete."
}

# Run necessary functions in order
run-as-root
reset_k8s_cluster
uninstall_cni
uninstall_openebs
cleanup

cecho "GREEN" "Uninstallation completed."

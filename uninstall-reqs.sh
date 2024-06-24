#!/bin/bash
#
# Description: This script uninstalls all components installed by the install-reqs.sh script.
# Author: Niloy Saha (version 1.0)
#         Shayan Mohammadi Kubijari (version 1.1)
# Last Mod Date: 2024/06/08
# Usage: Please ensure that you run this script as ROOT or with ROOT permissions.
# Notes: This script is designed for use with Ubuntu 22.04.
# ==============================================================================

cecho() {
  case "$1" in
    "RED") color="\033[0;31m" ;;
    "GREEN") color="\033[0;32m" ;;
    "YELLOW") color="\033[0;33m" ;;
    *) color="\033[0m" ;;  # No Color
  esac
  echo -e "${color}$2\033[0m"
}

run-as-root() {
  if [ "$EUID" -ne 0 ]; then
    cecho "RED" "This script must be run as ROOT"
    exit 1
  fi
}

uninstall_docker() {
  cecho "RED" "Uninstalling Docker and related components..."
  sudo apt-mark unhold docker-ce docker-ce-cli
  sudo docker image prune -a -f
  sudo docker system prune -a -f
  sudo apt purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras
  sudo rm -rf /etc/docker /var/lib/docker /var/lib/containerd /etc/containerd
  cecho "GREEN" "Docker and related packages have been uninstalled."
}

uninstall_k8s() {
  cecho "RED" "Uninstalling Kubernetes components..."
  sudo apt-mark unhold kubelet kubeadm kubectl
  sudo apt purge -y kubelet kubeadm kubectl kubernetes-cni kube*
  sudo rm -rf /etc/kubernetes /var/lib/kubelet /var/lib/etcd /var/run/kubernetes
  cecho "GREEN" "Kubernetes components have been uninstalled."
}

uninstall_helm() {
  cecho "RED" "Removing Helm..."
  sudo apt-mark unhold helm
  sudo apt purge -y helm
  cecho "GREEN" "Helm has been removed."
}

cleanup() {
  cecho "RED" "Performing final cleanup..."
  sudo rm -rf build
  sudo apt autoremove -y
  sudo apt clean
  cecho "GREEN" "Cleanup complete."
}

# Start execution
run-as-root
uninstall_helm
uninstall_k8s
uninstall_docker
cleanup

cecho "GREEN" "Uninstallation of all components completed successfully."

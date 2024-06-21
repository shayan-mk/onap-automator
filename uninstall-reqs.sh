#!/bin/bash
#
# Description: This script uninstalls the stuff installed using install-reqs.sh
# Author: Niloy Saha                    (version 1.0)
#         Shayan Mohammadi Kubijari     (version 1.1)
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

uninstall_docker() {
  cecho "RED" "Uninstalling docker ..."
  sudo apt-mark unhold docker-ce docker-ce-cli
  sudo docker image prune -a
  sudo docker system prune -a
  sudo apt purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras
  sudo rm -rf /etc/containerd /var/lib/docker /var/lib/containerd
  cecho "GREEN" "Docker and related packages have been uninstalled."
}

uninstall_k8s() {
  cecho "RED" "Uninstalling Kubernetes components (kubectl, kubeadm, kubelet)..."
  sudo apt-mark unhold kubelet kubeadm kubectl
  sudo apt purge -y kubelet kubeadm kubectl kubernetes-cni kube*
  cecho "GREEN" "Kubernetes components have been deleted."
}

uninstall_helm() {
  cecho "RED" "Removing Helm3"
  sudo apt-mark unhold helm
  sudo apt purge -y helm
  cecho "GREEN" "Helm3 has been removed."
}

cleanup() {
  cecho "RED" "Cleaning up build directories and redundant packages ..."
  sudo rm -rf build
  sudo apt autoremove -y
}

uninstall_helm
uninstall_k8s
uninstall_docker
cleanup

cecho "GREEN" "Uninstallation completed."

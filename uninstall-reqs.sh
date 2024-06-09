#!/bin/bash
#
# Description: This script uninstalls the stuff installed using install-reqs.sh
# Author: Niloy Saha                    (version 1.0)
#         Shayan Mohammadi Kubijari     (version 1.1)
# Last Mod Date: 2024/06/08
# Usage: Please ensure that you run this script as ROOT or with ROOT permissions.
# Notes: This script is designed for use with Ubuntu 22.04.
# ==============================================================================

run-as-root(){
  if [ "$EUID" -ne 0 ]
  then cecho "RED" "This script must be run as ROOT"
  exit
  fi
}

timer-sec(){
  secs=$((${1}))
  while [ $secs -gt 0 ]; do
    echo -ne "Waiting for $secs\033[0K seconds ...\r"
    sleep 1
    : $((secs--))
  done
}

# Based on https://stackoverflow.com/a/53463162/9346339
cecho(){
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
  if [ -x "$(command -v docker)" ]; then
    sudo apt-mark unhold docker-ce docker-ce-cli
    sudo docker image prune -a
    sudo docker system prune -a
    sudo systemctl restart docker
    sudo apt purge -y docker-engine docker docker.io docker-ce docker-ce-cli containerd containerd.io runc --allow-change-held-packages
  else
    cecho "YELLOW" "Docker is not installed."
  fi
}

uninstall_containerd() {
  cecho "RED" "Uninstalling containerd ..."
  if [ -x "$(command -v containerd)" ]; then
    sudo apt-mark unhold docker-ce docker-ce-cli
    sudo systemctl stop containerd
    sudo apt-get remove --purge -y containerd.io docker-ce docker-ce-cli --allow-change-held-packages
    sudo rm -rf /etc/containerd
    cecho "GREEN" "Containerd and related packages have been uninstalled."
  else
    cecho "YELLOW" "Containerd is not installed."
  fi
}


uninstall_k8s() {
  cecho "RED" "Uninstalling Kubernetes components (kubectl, kubeadm, kubelet)..."
  if [ -x "$(command -v kubectl)" ] && [ -x "$(command -v kubeadm)" ] && [ -x "$(command -v kubelet)" ]; then
    sudo apt-mark unhold kubelet kubeadm kubectl
    sudo apt-get remove --purge -y --allow-change-held-packages kubelet kubeadm kubectl kubernetes-cni kube* 
    cecho "GREEN" "Kubernetes components have been deleted."
  else
    cecho "YELLOW" "Kubernetes components (kubectl, kubeadm, kubelet) are not installed."
  fi

}

uninstall_helm() {
  cecho "RED" "Removing Helm3"
  if [ -x "$(command -v helm)" ]; then
    sudo apt-mark unhold helm
    sudo apt-get remove --purge -y --allow-change-held-packages helm
    cecho "GREEN" "Helm3 has been removed."
  else
    cecho "YELLOW" "Helm3 is not installed"
  fi
}

cleanup() {
  cecho "RED" "Cleaning up build directories and redundant packages ..."
  sudo rm -rf build
  sudo apt-get -y autoremove
}

uninstall_helm
uninstall_k8s
uninstall_containerd
uninstall_docker
cleanup

cecho "GREEN" "Uninstallation completed."

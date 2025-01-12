#!/bin/bash

DOCKER_VERSION="5:20.10.24~3-0~ubuntu-jammy"
sudo rm -f /etc/apt/sources.list.d/helm-stable-debian.list /etc/apt/sources.list.d/kubernetes.list
sudo apt update
sudo apt-mark unhold "docker*" "helm*" "kube*"
sudo apt purge -y docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc "helm*" "kube*"
sudo apt upgrade -y --allow-downgrades docker-ce=$DOCKER_VERSION docker-ce-cli=$DOCKER_VERSION  docker-ce-rootless-extras=$DOCKER_VERSION containerd.io docker-buildx-plugin docker-compose-plugin
sudo apt-mark hold "docker-ce*"
sudo apt -y autoremove
sudo apt -y autoclean
docker system prune -af
#sudo reboot

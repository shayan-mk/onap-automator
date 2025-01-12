#!/bin/bash
curl -Lo /tmp/cni-plugins-linux-amd64-v1.1.1.tgz https://github.com/containernetworking/plugins/releases/download/v1.1.1/cni-plugins-linux-amd64-v1.1.1.tgz
sudo tar -C /opt/cni/bin -xzf /tmp/cni-plugins-linux-amd64-v1.1.1.tgz

#!/bin/bash

sudo apt update
cd ~
if [[ ! -d "onap-automator" ]]; then
    echo "onap-automator doesn't exist. cloning..."
    git clone https://github.com/shayan-mk/onap-automator.git
fi

cd ~/onap-automator
git fetch
git reset --hard origin/main

./uninstall-reqs.sh
#sudo apt full-upgrade -y
sudo reboot

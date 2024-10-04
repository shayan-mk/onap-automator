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

#sudo apt upgrade -y
#sudo apt autoremove -y
./install-reqs.sh
sudo reboot

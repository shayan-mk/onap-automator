#!/bin/bash

VERSION=14.0.0
PASSWORD=onap

cd $(dirname -- $0)/helm-plugins
helm plugin install deploy
helm plugin install undeploy

cd ~
if [[ ! -d "oom" ]]; then
    echo "oom doesn't exist. cloning..."
    git clone https://github.com/onap/oom.git
fi

cd ~/oom/kubernetes/onap/resources/overrides/
git reset --hard origin/master
helm deploy onap onap-release/onap --namespace onap --create-namespace --set global.masterPassword=$PASSWORD --version $VERSION -f onap-all.yaml -f environment.yaml  > ~/onap-commands.log

cd $(dirname -- $0)
basic_components="onap roles-wrapper repository-wrapper strimzi cassandra mariadb-galera postgres"
for component in $basic_components
do
  ./sub-deploy.sh $component
done

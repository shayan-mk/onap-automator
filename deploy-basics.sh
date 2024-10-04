#!/bin/bash

set -x

basic_components="onap roles-wrapper repository-wrapper cert-wrapper cassandra mariadb-galera postgres"

for component in $basic_components
do
  $(dirname -- $0)/sub-deploy.sh $component
done

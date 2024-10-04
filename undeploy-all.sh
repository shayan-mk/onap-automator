#!/bin/bash

set -x

for chart in $(helm list -n onap | tail -n +2 | awk 'BEGIN { ORS=" " }; {print $1}')
do 
  helm del -n onap $chart
done

kubectl delete ns onap


#!/bin/bash

cd ~/onap-automator/
components="a1policymanagement aai cds cli cps dcaegen2-services holmes dmaap modeling msb multicloud nbi oof platform policy portal-ng robot sdc sdnc so uui vfc vnfsdk"
for comp in $components
do
  ./sub-deploy.sh $comp
done

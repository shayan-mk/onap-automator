#!/bin/bash

set -x


if [ "$#" -ne 2 ]; then
        echo "usage: ./sub_deploy.sh <deployment name> <subchart name>"
	echo "for the onap deployment itself run ./sub_deploy.sh <deployment name> onap"
        exit 1
fi

CACHE_DIR="${HOME}/.local/share/helm/plugins/deploy/cache"

if [ "${2}" == "onap" ]; then
	helm upgrade -i ${1} ${CACHE_DIR}/onap  --namescape onap --create-namespace -f ${CACHE_DIR}/onap/computed-overrides.yaml > ${CACHE_DIR}/onap/logs/${1}.log 2>&1
else
	helm upgrade -i ${1}-${2} ${CACHE_DIR}/onap-subcharts/${2} --namespace onap --create-namespace -f ${CACHE_DIR}/onap/global-overrides.yaml -f ${CACHE_DIR}/onap-subcharts/${2}/subchart-overrides.yaml  > ${CACHE_DIR}/onap/logs/${1}-${2}.log 2>&1
fi

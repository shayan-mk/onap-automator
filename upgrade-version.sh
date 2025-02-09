#!/bin/bash

set -x

if [ "$#" -ne 2 ] || [ -z "$1" ]; then
	echo "usage: bash sub_deploy.sh <subchart name> <version>"
	echo "For the initail onap deployment, run bash sub_deploy.sh onap"
	exit 1
fi

CACHE_DIR="${HOME}/.local/share/helm/plugins/deploy/cache"

if [ "${1}" == "onap" ]; then
	helm upgrade -i onap onap-testing/onap --namespace onap --create-namespace --version ${2} -f ${CACHE_DIR}/onap/computed-overrides.yaml >${CACHE_DIR}/onap/logs/onap.log 2>&1
else
	helm upgrade -i onap-${1} onap-testing/${1} --namespace onap --create-namespace  --version ${2} -f ${CACHE_DIR}/onap/global-overrides.yaml -f ${CACHE_DIR}/onap-subcharts/${1}/subchart-overrides.yaml >${CACHE_DIR}/onap/logs/onap-${1}.log 2>&1
fi

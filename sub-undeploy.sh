#!/bin/bash

set -x

if [ "$#" -ne 1 ] || [ -z "$1" ]; then
        echo "usage: bash sub-undeploy.sh <subchart name>"
        echo "For the initail onap deployment, run bash sub-undeploy.sh onap"
        exit 1
fi


if [ "${1}" == "onap" ]; then
	helm del -n onap onap
else
	helm del -n onap onap-${1}
fi

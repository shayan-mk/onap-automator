#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 {control|worker|all} </path/to/script.sh>"
    exit 1
fi

# Check if the target group is valid
EXEC_MODE=$1
if [[ ! "$EXEC_MODE" =~ ^(control|worker|all)$ ]]; then
    echo "Error: Invalid exec mode specified ('$EXEC_MODE')."
    echo "       Must be one of: control, worker, all."
    exit 1
fi

# Check if the script file exists and is executable
SCRIPT_PATH=$2
if [ ! -x "$SCRIPT_PATH" ]; then
    echo "Error: The specified script ('$SCRIPT_PATH') does not exist or is not executable."
    exit 1
fi

execute_script() {
    local type=$1
    local count=$2

    for i in $(seq 1 $count); do
        server="onap-${type}-$i"
        echo "Copying script to $server"
        scp "$SCRIPT_PATH" "${server}:~/"

        echo "Executing script on $server"
        ssh -t "$server" "sudo bash ~/$(basename "$SCRIPT_PATH")"
    done
}

case $EXEC_MODE in
control)
    execute_script "control" 4
    ;;
worker)
    execute_script "k8s" 10
    ;;
all)
    execute_script "control" 4
    execute_script "k8s" 10
    ;;
esac

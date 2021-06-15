#!/bin/bash

# Trap ctrl-c and call ctrl_c()
trap ctrl_c INT

function ctrl_c() {
    echo "Bye!"
    exit 0
}

function check_connectivity() {

    if ! curl --output /dev/null --silent --head --fail http://cloud.ibm.com; then
        echo
        echo "ERROR: please, check your internet connection."
        exit 1
    fi
}

function check_dependencies() {

    DEPENDENCIES=(ibmcloud curl sh wget jq)
    check_connectivity
    ibmcloud update -f
    for i in "${DEPENDENCIES[@]}"
    do
        if ! command -v "$i" &> /dev/null; then
            echo "$i could not be found, exiting!"
            exit
        fi
    done
}

function authenticate() {
    
    local APY_KEY="$1"
    
    if [ -z "$APY_KEY" ]; then
        echo "API KEY was not set."
        exit 1
    fi
    ibmcloud login --no-region --apikey "$APY_KEY"
}

function set_powervs() {
    
    local CRN="$1"
    
    if [ -z "$CRN" ]; then
        echo "CRN was not set."
        exit 1
    fi
    ibmcloud pi st "$CRN"
}

function operation(){

    OPERATION=$1
    CLUSTER_ID=$2

    ibmcloud pi ins --json | jq -r '.Payload.pvmInstances[] | "\(.pvmInstanceID),\(.serverName)"' | \
    grep "$CLUSTER_ID" | awk -F ',' '{print $1}' | xargs -n1 ibmcloud pi "$OPERATION"
}

main (){

    if [ -z "$API_KEY" ]; then
        echo "API_KEY was not set."
        exit 1
    fi

    if [ -z "$POWERVS_CRN" ]; then
        echo "POWERVS_CRN was not set."
        exit 1
    fi

    if [ -z "$CLUSTER_ID" ]; then
        echo "CLUSTER_ID was not set."
        exit 1
    fi

    if [ -z "$OPERATION" ]; then
        echo "OPERATION was not set."
        exit 1
    fi

    check_dependencies
    check_connectivity
    authenticate "$API_KEY"
    set_powervs "$POWERVS_CRN"  

    case $OPERATION in
    start)
        operation "start" "$CLUSTER_ID"
        ;;
    stop)
        operation "stop" "$CLUSTER_ID"
        ;;
    hard-reboot)
        operation "hard-reboot" "$CLUSTER_ID"
        ;;
    soft-reboot)
        operation "soft-reboot" "$CLUSTER_ID"
        ;;
    immediate-shutdown)
        operation "immediate-shutdown" "$CLUSTER_ID"
        ;;
    *)
        echo -n "ERROR: Option not available."
        ;;
    esac
}

main "$@"

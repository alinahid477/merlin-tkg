#!/bin/bash


function patchNSXALB () {
    local nsxalbVersion=$1
    if [[ -z $nsxalbVersion ]]
    then
        nsxalbVersion='21.1.3'
        printf "${redcolor}No nsx alb version supplied as parameter. Assuming default version: $nsxalbVersion\n"
        sleep 2
    fi

    printf "\n\n********* Patching KB:https://kb.vmware.com/s/article/87640 **************\n\n"

    kubectl patch pkgi ako-operator -n tkg-system --type "json" -p '[{"op":"replace","path":"/spec/paused","value":true}]'
    sleep 1
    kubectl set env deployment/ako-operator-controller-manager avi_controller_version="$nsxalbVersion" -n tkg-system-networking
    sleep 2
    AKOoperatorPod=kubectl get pod -n tkg-system-networking -o json | jq -r '.items[] | select(.metadata.name | startswith("ako-operator-controller-manager-")) | .metadata.name'
    kubectl delete pod $AKOoperatorPod -n tkg-system-networking
    unset AKOoperatorPod

    printf "\n\n********* Patching -- COMPLETED **************\n\n"
}

patchNSXALB
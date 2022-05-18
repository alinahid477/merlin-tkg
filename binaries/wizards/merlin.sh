#!/bin/bash


function helpFunction()
{
    printf "\n"
    echo "Usage:"
    echo -e "\t-m | --management-cluster-deploy no value needed. Signals the wizard to start the process for deploying management cluster."
    echo -e "\t-w | --workload-cluster no value needed. Signals the wizard to launch the UI for user input to take necessary inputs and deploy TKG workload cluster"
    echo -e "\t-f | --config-file pass a file containing configs for tkg workload cluster. This signals the wizard for NOT launching UI but deploy workload cluster using the config file supplied."
    echo -e "\t-t | --tanzu-management-connect no value needed. Signals the wizard to start the process for connecting to tanzu cluster as per ~/.config/config.yaml and kubeconfig."
    echo -e "\t-h | --help"
    printf "\n"
}


output=""

# read the options
TEMP=`getopt -o mwtf:h --long management-cluster-deploy,workload-cluster,tanzu-management-connect,tkg-config-file:,help -n $0 -- "$@"`
eval set -- "$TEMP"
# echo $TEMP;
while true ; do
    # echo "here -- $1"
    case "$1" in
        -m | --management-cluster-deploy )
            case "$2" in
                "" ) managementClusterDeploy='y';  shift 2 ;;
                * ) managementClusterDeploy='y' ;  shift 1 ;;
            esac ;;
        -w | --workload-cluster )
            case "$2" in
                "" ) workloadCluster='y'; shift 2 ;;
                * ) workloadCluster='y' ; shift 1 ;;
            esac ;;
        -t | --tanzu-management-connect )
            case "$2" in
                "" ) tanzuManagementConnect='y';  shift 2 ;;
                * ) tanzuManagementConnect='y' ;  shift 1 ;;
            esac ;;
        -f | --config-file )
            case "$2" in
                "" ) configFile=''; shift 2 ;;
                * ) configFile=$2;  shift 2 ;;
            esac ;;
        -h | --help ) helpFunction; break;; 
        -- ) shift; break;; 
        * ) break;;
    esac
done

if [[ $managementClusterDeploy == 'y' ]]
then
    source $HOME/binaries/wizards/tkginstall.sh
    unset managementClusterDeploy
fi

if [[ $tanzuManagementConnect == 'y' ]]
then
    printf "\n\n************Connecting Tanzu Management to k8s**************\n\n"
    source $HOME/binaries/scripts/tanzu_connect.sh
    tanzu_connect_and_confirm
    printf "DONE\n\n\n"
    unset tanzuManagementConnect
fi

if [[ $workloadCluster == 'y' ]]
then
    if [[ -z $configFile ]]
    then
        source $HOME/binaries/wizards/tkgworkloadui.sh
    else
        source $HOME/binaries/wizards/tkgworkloadui.sh $configFile
    fi
    unset workloadCluster
    unset configFile
fi
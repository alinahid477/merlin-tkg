#!/bin/bash

export $(cat /root/.env | xargs)

source $HOME/binaries/scripts/returnOrexit.sh
source $HOME/binaries/scripts/generate-tkg-file.sh


function launchUI () {
    local yellowcolor=$(tput setaf 3)
    local magentacolor=$(tput setaf 5)
    local normalcolor=$(tput sgr0)

    printf "\n\n*******Starting TKG workload cluster wizard*******\n\n"

    generateTKCFile
    ret=$?
    if [[ $ret != 0 || -z $CLUSTER_NAME ]]
    then
        printf "\n${magentacolor}ERROR: error occured generating config file for workload cluster.${normalcolor}\n"
        return 1        
    fi

    printf "\nReview and confirm generated Workload cluster config file: ${yellowcolor}$HOME/workload-clusters/tkg-$CLUSTER_NAME.yaml.${normalcolor}\n"
    
    local confirmation=''
    while true; do
        read -p "confirm to create tkg workload cluster using this config file [y/n]: " yn
        case $yn in
            [Yy]* ) confirmation="y"; printf "you confirmed yes\n"; break;;
            [Nn]* ) confirmation="n";printf "You confirmed no.\n"; return 1;;
            * ) echo "Please answer y or n.";;
        esac
    done
    

    printf "Executing tanzu clauster create using file ${yellowcolor}$HOME/workload-clusters/tkg-$CLUSTER_NAME.yaml.${normalcolor}....\n"
}

launchUI
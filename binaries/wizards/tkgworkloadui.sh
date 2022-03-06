#!/bin/bash

export $(cat /root/.env | xargs)

source $HOME/binaries/scripts/returnOrexit.sh
source $HOME/binaries/scripts/generate-tkg-file.sh


function launchUI () {
    local tkcconfigfile=$1

    printf "\n\n*******Starting TKG workload cluster wizard*******\n\n"

    local confirmation=''
    
    if [[ -n $tkcconfigfile ]]
    then
        printf "\n${yellowcolor}No wizard required. Provided config file: $tkcconfigfile.${normalcolor}\n"
        confirmation='y'
        sleep 1
    else
        generateTKCFile
        ret=$?
        if [[ $ret != 0 || -z $CLUSTER_NAME ]]
        then
            printf "\n${redcolor}ERROR: error occured generating config file for workload cluster.${normalcolor}\n"
            return 1        
        fi

        tkcconfigfile="$HOME/workload-clusters/tkg-$CLUSTER_NAME.yaml"
        printf "\nReview and confirm generated Workload cluster config file: ${yellowcolor}$tkcconfigfile.${normalcolor}\n"
        
        
        while true; do
            read -p "confirm to create tkg workload cluster using this config file [y/n]: " yn
            case $yn in
                [Yy]* ) confirmation="y"; printf "you confirmed yes\n"; break;;
                [Nn]* ) confirmation="n";printf "You confirmed no.\n"; return 1;;
                * ) echo "Please answer y or n.";;
            esac
        done
    fi
   
    
    if [[ $confirmation == 'y' ]]
    then

        local INFRASTRUCTURE_PROVIDER=$(cat $tkcconfigfile | sed -r 's/[[:alnum:]]+=/\n&/g' | awk -F: '$1=="INFRASTRUCTURE_PROVIDER"{print $2}' | xargs)
        if [[ -n $INFRASTRUCTURE_PROVIDER ]]
        then
            source $HOME/binaries/scripts/clouds/$INFRASTRUCTURE_PROVIDER/deploy-tkc.sh
            deployTKC $tkcconfigfile || returnOrexit || return 1
        else
            printf "\n${redcolor}ERROR: INFRASTRUCTURE_PROVIDER information is missing from the config file${normalcolor}\n"
        fi
    fi

}

launchUI $1
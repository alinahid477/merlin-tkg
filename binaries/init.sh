#!/bin/bash

export $(cat /root/.env | xargs)

if [ ! -f "$HOME/binaries/scripts/install-tanzu-cli.sh" ]
then
    if [[ ! -d  "$HOME/binaries/scripts" ]]
    then
        mkdir -p $HOME/binaries/scripts
    fi
    printf "\n\n************Downloading Common Scripts**************\n\n"
    curl -L https://raw.githubusercontent.com/alinahid477/common-merlin-scripts/main/scripts/download-common-scripts.sh -o /tmp/download-common-scripts.sh
    chmod +x /tmp/download-common-scripts.sh
    ./tmp/download-common-scripts.sh all $HOME/binaries/scripts/
    sleep 1
    printf "setting executable permssion common scripts..."    
    ls -l $HOME/binaries/scripts/*.sh | awk '{print $9}' | xargs chmod +x
    printf "COMPLETED"
    printf "\n\n"
fi

source $HOME/binaries/scripts/returnOrexit.sh


printf "\n\nsetting executable permssion to all binaries sh\n\n"
ls -l $HOME/binaries/*.sh | awk '{print $9}' | xargs chmod +x
ls -l $HOME/binaries/templates/* | awk '{print $9}' | xargs chmod +x

source $HOME/binaries/scripts/init-prechecks.sh

printf "\n\n************Checking installed binaries**************\n\n"
source $HOME/binaries/scripts/install-tanzu-cli.sh
installTanzuCLI
printf "DONE\n\n\n"

if [[ -f $HOME/.kube-tkg/config ]]
then
    printf "\n\n************Connecting Tanzu Management to k8s**************\n\n"
    source $HOME/binaries/scripts/tanzu_connect.sh
    tanzu_connect_and_confirm
    printf "DONE\n\n\n"
fi

printf "\n\n\nYour available wizards are:\n"
echo -e "\t~/binaries/tkginstall.sh --help"
echo -e "\t~/binaries/tkgworkloadwizard.sh --help"
echo -e "\t~/binaries/tkgconnect.sh --help"

cd ~


/bin/bash
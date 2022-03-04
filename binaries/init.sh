#!/bin/bash

export $(cat /root/.env | xargs)


if [ ! -f "$HOME/binaries/scripts/returnOrexit.sh" ]
then
    if [[ ! -d  "$HOME/binaries/scripts" ]]
    then
        mkdir -p $HOME/binaries/scripts
    fi
    printf "\n\n************Downloading Common Scripts**************\n\n"
    curl -L https://raw.githubusercontent.com/alinahid477/common-merlin-scripts/main/scripts/download-common-scripts.sh -o $HOME/binaries/scripts/download-common-scripts.sh
    chmod +x $HOME/binaries/scripts/download-common-scripts.sh
    $HOME/binaries/scripts/download-common-scripts.sh tkg scripts
    sleep 1
    $HOME/binaries/scripts/download-common-scripts.sh clouds.vsphere scripts/clouds/vsphere
    sleep 1
    if [[ -n $BASTION_HOST ]]
    then
        $HOME/binaries/scripts/download-common-scripts.sh bastion scripts/bastion
        sleep 1
    fi
    printf "\n\n\n///////////// COMPLETED //////////////////\n\n\n"
    printf "\n\n"
fi

source $HOME/binaries/scripts/returnOrexit.sh
source $HOME/binaries/scripts/color-file.sh

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
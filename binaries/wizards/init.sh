#!/bin/bash

export $(cat /root/.env | xargs)

if [[ -z $CLOUD ]]
then
    printf "\n\nERROR: no cloud mentioned. Please provide CLOUD=<vsphere or aws or azure> in .env file\n\n"
    exit 1
fi

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
    $HOME/binaries/scripts/download-common-scripts.sh clouds.$CLOUD scripts/clouds/$CLOUD
    sleep 1
    if [[ -n $BASTION_HOST ]]
    then
        $HOME/binaries/scripts/download-common-scripts.sh bastion scripts/bastion
        sleep 1
    fi
    printf "\n\n\n///////////// COMPLETED //////////////////\n\n\n"
    printf "\n\n"
fi

printf "\n\nsetting executable permssion to all binaries sh\n\n"
ls -l $HOME/binaries/wizards/*.sh | awk '{print $9}' | xargs chmod +x
ls -l $HOME/binaries/templates/* | awk '{print $9}' | xargs chmod +x

source $HOME/binaries/scripts/returnOrexit.sh
source $HOME/binaries/scripts/color-file.sh
source $HOME/binaries/scripts/init-prechecks.sh


printf "\n\n************Checking installed $CLOUD cli **************\n\n"
source $HOME/binaries/scripts/install-cloud-cli.sh
installTanzuCLI
printf "DONE\n\n\n"


printf "\n\n************Checking installed tanzu binaries**************\n\n"
source $HOME/binaries/scripts/install-tanzu-cli.sh
installCloudCLI $CLOUD || returnOrexit || exit 1
printf "DONE\n\n\n"



if [[ -f $HOME/.kube-tkg/config ]]
then
    printf "\n\n************Connecting Tanzu Management to k8s**************\n\n"
    source $HOME/binaries/scripts/tanzu_connect.sh
    tanzu_connect_and_confirm
    printf "DONE\n\n\n"
else
    source $HOME/binaries/scripts/clouds/$CLOUD/$CLOUD.sh
    prepareAccountForTKG || returnOrexit || exit 1
fi

printf "\n\n\n${greencolor}RUN merlin --help for details on how to use this UI${normalcolor}\n"

cd ~


/bin/bash
#!/bin/bash

export $(cat /root/.env | xargs)
unset doinstall

if [ ! -f "$HOME/binaries/scripts/install-tanzu-framework-tarfile.sh" ]
then
    printf "\n\n************Downloading Common Scripts**************\n\n"
    curl -L https://raw.githubusercontent.com/alinahid477/common-merlin-scripts/main/scripts/download-common-scripts.sh -o /tmp/download-common-scripts.sh
    chmod +x /tmp/download-common-scripts.sh
    ./tmp/download-common-scripts.sh all $HOME/binaries/scripts/
fi

printf "\n\nsetting executable permssion to all binaries sh\n\n"
ls -l $HOME/binaries/*.sh | awk '{print $9}' | xargs chmod +x
ls -l $HOME/binaries/scripts/*.sh | awk '{print $9}' | xargs chmod +x
ls -l $HOME/binaries/templates/*.sh | awk '{print $9}' | xargs chmod +x

source $HOME/binaries/scripts/init-prechecks.sh

printf "\n\n************Checking installed binaries**************\n\n"
source $HOME/binaries/scripts/install-tanzu-framework-tarfile.sh
installTanzuFrameworkTarFile
printf "DONE\n\n\n"

/bin/bash
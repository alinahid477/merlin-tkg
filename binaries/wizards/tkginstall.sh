#!/bin/bash

unset TKG_ADMIN_EMAIL
unset MANAGEMENT_CLUSTER_CONFIG_FILE
unset BASTION_HOST
unset BASTION_USERNAME

export $(cat /root/.env | xargs)

source $HOME/binaries/scripts/returnOrexit.sh


helpFunction()
{
    printf "\nNo parameter to pass.\nThis is a wizard based installation.\n"
    printf "\tThe wizard will take care of few of the installation pre-requisites through asking for some basic input. Just follow the prompt.\n"
    printf "\tOnce the prerequisites conditions are staisfied the wizard will then proceed on launching tkg installation UI.\n"
    printf "\tWhen using bastion host the wizard will connect to bastion host and check for the below prequisites:\n"
    printf "\t\t- Bastion host must have docker engine (docker ce or docker ee) installed. (if you do not have it installed please do so now)\n"
    printf "\t\t- Bastion host must have php installed. (if you do not have it installed please do so now).\n"
    printf "\n\n"
    returnOrexit || return 1 # Exit script after printing help
}


function tkginstall() {

    if [[ -f $HOME/.kube-tkg/config ]]
    then
        printf "\n\nERROR: kube-tkg-config file already exists in $HOME/.kube-tkg/config.\n"
        printf "\n\n\nRUN ~/binaries/tkgworkloadwizard.sh --help to start creating workload clusters.\n\n\n"
        returnOrexit || return 1  
    fi
    
    printf "\n***************************************************"
    printf "\n********** Starting *******************************"
    printf "\n***************************************************"

    printf "\n\n\n"

    if [[ -z $CLOUD ]]
    then
        printf "\n${redcolor}ERROR: No value for environment variable CLOUD. This value must exists.${normalcolor}\n"
        returnOrexit || return 1
    fi

    if [[ $CLOUD == 'aws' ]]
    then
        # by the time the code reaches here there should already key kp uploaded to aws. see aws.sh
        source $HOME/binaries/scripts/clouds/aws/aws.sh
        local awsKPname=$(getKeyPairName)

        if [[ -z $awsKPname ]]
        then
            printf "\n${redcolor}ERROR: aws key pair name could not be retrieved.${normalcolor}\n"
            returnOrexit || return 1
        fi

        printf "\n\n\n Here's your key pair name for aws: $awsKPname\n"
    else

        # Generate key pair when it is not aws.
        isexists=$(ls .ssh/tkg_rsa.pub)
        if [[ -z $isexists ]]
        then
            if [[ -z $TKG_ADMIN_EMAIL ]]
            then
                printf "TKG_ADMIN_EMAIL not set in the .env file."
                printf "\n"
                if [[ -z $SILENTMODE || $SILENTMODE != 'YES' ]]
                then
                    printf "\nERROR: tkg admin email not set.\n"
                    returnOrexit || return 1
                fi
                while true; do
                    read -p "TKG_ADMIN_EMAIL: " inp
                    if [ -z "$inp" ]
                    then
                        printf "\nThis is required.\n"
                    else 
                        TKG_ADMIN_EMAIL=$inp
                        break;
                    fi
                done        
                printf "\nTKG_ADMIN_EMAIL=$TKG_ADMIN_EMAIL" >> /root/.env
                sleep 1
                export $(cat /root/.env | xargs)
            else
                printf "\nUsing TKG_ADMIN_EMAIL=$TKG_ADMIN_EMAIL from environment variable...no need to collect from user.\n"
            fi
            

            printf "\n\n\nexecuting ssh-keygen with email $TKG_ADMIN_EMAIL...\n"
            ssh-keygen -f ~/.ssh/tkg_rsa -t rsa -b 4096 -C "$TKG_ADMIN_EMAIL"
            printf "\nDONE.\n"
        else 
            isexists=$(ls .ssh/tkg_rsa)
            if [[ -z $isexists ]]
            then
                printf "\n\nERROR: found tkg_rsa.pub in the .ssh dir BUT did not find private key to add named tkg_rsa."
                printf "\n\tPlease remove the tkg_rsa.pub to re-create key pair OR provide private key tkg_rsa file"
                printf "\n\tQuiting..."
                returnOrexit || return 1
            fi
        fi
    fi

    if [[ -n $BASTION_HOST ]]
    then
        echo "=> Bastion host detected. Tkg installation will launch merlin-tkg docker in the remote host."
        local confirmation='y'
        if [[ -z $SILENTMODE || $SILENTMODE != 'YES' ]]
        then
            while true; do
                read -p "Confirm to continue [yn]? " yn
                case $yn in
                    [Yy]* ) printf "\nyou confirmed yes\n"; break;;
                    [Nn]* ) confirmation='n'; printf "\nyou confirmed no\n"; break;;
                    * ) echo "Please answer y when you are ready.";;
                esac
            done
        fi
        if [[ $confirmation == 'n' ]]
        then
            returnOrexit || return 1
        fi
        source $HOME/binaries/scripts/bastion/bastionhostmanagementsetup.sh
        auto_tkginstall || returnOrexit || return 1
    else
        if [[ $CLOUD == 'azure' ]]
        then
            source $HOME/binaries/scripts/clouds/azure/azure.sh
            prepareAccountForTKG
        fi
        if [[ $CLOUD != 'aws' ]]
        then
            # aws does not need a rsa key. This is already uploaded in aws kp. See above. and aws.sh
            printf "\n\n\n Here's your public key in ~/.ssh/id_rsa.pub:\n"
            cat ~/.ssh/tkg_rsa.pub
        fi

        if [[ -n $MANAGEMENT_CLUSTER_CONFIG_FILE ]]
        then
            printf "\nLaunching management cluster create using $MANAGEMENT_CLUSTER_CONFIG_FILE...\n"
            tanzu management-cluster create --file $MANAGEMENT_CLUSTER_CONFIG_FILE -v 9
        else
            printf "\nLaunching management cluster create using UI...\n"
            local bindparam=''
            if [[ -n $BIND_ADDRESS ]]
            then
                bindparam="--bind $BIND_ADDRESS"
            fi
            tanzu management-cluster create $bindparam --ui -y -v 9 --browser none
        fi
    fi   


    # ISPINNIPED=$(kubectl get svc -n pinniped-supervisor | grep pinniped-supervisor)

    # if [[ ! -z "$ISPINNIPED" ]]
    # then
    #     printf "\n\n\nBelow is details of the service for the auth callback url. Update your OIDC/LDAP callback accordingly.\n"
    #     kubectl get svc -n pinniped-supervisor
    #     printf "\nDocumentation: https://docs.vmware.com/en/VMware-Tanzu-Kubernetes-Grid/1.3/vmware-tanzu-kubernetes-grid-13/GUID-mgmt-clusters-configure-id-mgmt.html\n"
    # fi

    # no need to marking as complete. I am checking ~/.kube-tkg/config instead.
    printf "\n\n\nCOMPLETE\n\n\n"

    # printf "\n\n\nDone. Marking as commplete.\n\n\n"
    # sed -i '/COMPLETE/d' .env
    # printf "\nCOMPLETE=YES" >> /root/.env


    printf "\n\n\nRUN merlin --workload-cluster to start creating workload clusters.\n\n\n"

    return 0
}


while getopts "h:" opt
do
    case $opt in
        h ) helpFunction; exit 0 ;;
        ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
    esac
done

tkginstall
ret=$?
if [[ $ret == 0 ]]
then
    if [[ -f $HOME/.kube-tkg/config ]]
    then
        printf "\n\n************Connecting Tanzu Management to k8s**************\n\n"
        source $HOME/binaries/scripts/tanzu_connect.sh
        tanzu_connect_and_confirm
        printf "DONE\n\n\n"
    fi
fi
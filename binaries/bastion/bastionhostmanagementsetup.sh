#!/bin/bash
export $(cat /root/.env | xargs)

remoteDIR="~/merlin/merlin-tkg"
remoteDockerName="merlin-tkg"
localBastionDIR=$HOME/binaries/bastion
localDockerContextName="merlin-bastion-docker-tkg"

function prechecks () {
    printf "\nperforming prerequisites checks...\n"

    isexist=$(ls $HOME/.ssh/id_rsa)
    if [[ -z $isexist ]]
    then
        printf "\nERROR: Failed. id_rsa file must exist in .ssh directory..."
        printf "\nPlease ensure to place id_rsa file in .ssh directory and the id_rsa.pub in .ssh of $BASTION_USERNAME@$BASTION_HOST"
        returnOrexit || return 1
    fi

    if [[ -z $DOCKERHUB_USERNAME || -z $DOCKERHUB_PASSWORD ]]
    then
        printf "\nERROR: Failed. docker hun username and password missing in env variable..."
        printf "\nPlease ensure DOCKERHUB_USERNAME and DOCKERHUB_PASSWORD in .env file"
        returnOrexit || return 1
    fi

    printf "\nChecking Docker on $BASTION_USERNAME@$BASTION_HOST...\n"
    isexist=$(ssh -i $HOME/.ssh/id_rsa $BASTION_USERNAME@$BASTION_HOST 'docker --version')
    if [[ -z $isexist ]]
    then
        printf "\nERROR: Failed. Docker not installed on bastion host..."
        printf "\nPlease install docker on host $BASTION_HOST to continue..."
        returnOrexit || return 1
    else
        printf "\nDocker found: $isexist"
    fi
    printf "\nChecking python3 on $BASTION_USERNAME@$BASTION_HOST...\n"
    isexist=$(ssh -i $HOME/.ssh/id_rsa $BASTION_USERNAME@$BASTION_HOST 'python3 --version')
    if [[ -z $isexist ]]
    then
        printf "\npython3 not found. checking python on $BASTION_USERNAME@$BASTION_HOST..."
        isexist=$(ssh -i $HOME/.ssh/id_rsa $BASTION_USERNAME@$BASTION_HOST 'python3 --version')
        if [[ -z $isexist ]]
        then
            printf "\nERROR: Failed. Python not installed on bastion host..."
            printf "\nPlease install Python on host $BASTION_HOST to continue..."
            returnOrexit || return 1
        else
            printf "\nDocker found: $isexist"
        fi
    else
        printf "\nPython found: $isexist"
    fi

    return 0
}


function prepareRemote () {
    printf "\nPreparing $BASTION_USERNAME@$BASTION_HOST for merlin\n"

    isexist=$(ssh -i $HOME/.ssh/id_rsa $BASTION_USERNAME@$BASTION_HOST 'ls -l '$remoteDIR)
    if [[ -z $isexist ]]
    then
        printf "\nCreating directory 'merlin' in $BASTION_USERNAME@$BASTION_HOST home dir"
        ssh -i $HOME/.ssh/id_rsa $BASTION_USERNAME@$BASTION_HOST 'mkdir -p '$remoteDIR'/binaries'
        ssh -i $HOME/.ssh/id_rsa $BASTION_USERNAME@$BASTION_HOST 'mkdir -p '$remoteDIR'/.ssh'
    fi

    printf "\nGetting remote files list from $BASTION_USERNAME@$BASTION_HOST\n"
    ssh -i $HOME/.ssh/id_rsa $BASTION_USERNAME@$BASTION_HOST 'ls '$remoteDIR'/binaries/' > /tmp/bastionhostbinaries.txt
    ssh -i $HOME/.ssh/id_rsa $BASTION_USERNAME@$BASTION_HOST 'ls '$remoteDIR'/' > /tmp/bastionhosthomefiles.txt
    ssh -i $HOME/.ssh/id_rsa $BASTION_USERNAME@$BASTION_HOST 'ls '$remoteDIR'/.ssh/' >> /tmp/bastionhosthomefiles.txt





    # default look for: tanzu tap cli
    tarfilenamingpattern="tanzu-framework-linux-amd64*"
    tanzuclibinary=$(ls $HOME/binaries/$tarfilenamingpattern)
    if [[ -z $tanzuclibinary ]]
    then
        # fallback look for: tanzu ent
        tarfilenamingpattern="tanzu-cli-*.tar.*"
        tanzuclibinary=$(ls $HOME/binaries/$tarfilenamingpattern)
    fi
    if [[ -z $tanzuclibinary ]]
    then
        # fallback look for: tanzu tce
        tarfilenamingpattern="tce-*.tar.*"
        tanzuclibinary=$(ls $HOME/binaries/$tarfilenamingpattern)
    fi
    isexist=$(cat /tmp/bastionhostbinaries.txt | grep -w $tanzuclibinary)
    if [[ -z $isexist ]]
    then
        printf "\nUploading $tanzuclibinary\n"
        scp $HOME/binaries/$tanzuclibinary $BASTION_USERNAME@$BASTION_HOST:$remoteDIR/binaries/
    fi

    isexist=$(cat /tmp/bastionhostbinaries.txt | grep -w "bastionhostinit.sh$")
    if [[ -z $isexist ]]
    then
        printf "\nUploading bastionhostinit.sh\n"
        scp $localBastionDIR/bastionhostinit.sh $BASTION_USERNAME@$BASTION_HOST:$remoteDIR/binaries/
    fi

    isexist=$(cat /tmp/bastionhosthomefiles.txt | grep -w "bastionhostrun.sh$")
    if [[ -z $isexist ]]
    then
        printf "\nUploading bastionhostrun.sh\n"
        scp $localBastionDIR/bastionhostrun.sh $BASTION_USERNAME@$BASTION_HOST:$remoteDIR/
    fi

    isexist=$(cat /tmp/bastionhosthomefiles.txt | grep -w "Dockerfile$")
    if [[ -z $isexist ]]
    then
        printf "\nUploading Dockerfile\n"
        scp $localBastionDIR/Dockerfile $BASTION_USERNAME@$BASTION_HOST:$remoteDIR/
    fi

    isexist=$(cat /tmp/bastionhosthomefiles.txt | grep -w "dockerignore$")
    if [[ -z $isexist ]]
    then
        printf "\nUploading .dockerignore\n"
        scp $HOME/.dockerignore $BASTION_USERNAME@$BASTION_HOST:$remoteDIR/
    fi

    isexist=$(ls ~/.ssh/tkg_rsa)
    isexistidrsa=$(cat /tmp/bastionhosthomefiles.txt | grep -w "id_rsa$")
    if [[ -n $isexist && -z $isexistidrsa ]]
    then
        printf "\nUploading .ssh/tkg_rsa\n"
        scp $HOME/.ssh/tkg_rsa $BASTION_USERNAME@$BASTION_HOST:$remoteDIR/.ssh/id_rsa
    fi

    if [[ -n $MANAGEMENT_CLUSTER_CONFIG_FILE ]]
    then
        printf "\nUploading $MANAGEMENT_CLUSTER_CONFIG_FILE\n"
        scp $MANAGEMENT_CLUSTER_CONFIG_FILE $BASTION_USERNAME@$BASTION_HOST:$remoteDIR/
    fi
}


function startTKGCreate () {
    printf "\nStarting remote docker with tanzu cli...\n"
    ssh -i $HOME/.ssh/id_rsa $BASTION_USERNAME@$BASTION_HOST 'chmod +x '$remoteDIR'/bastionhostrun.sh && '$remoteDIR'/bastionhostrun.sh '$DOCKERHUB_USERNAME $DOCKERHUB_PASSWORD


    printf "\nCreating remote context...\n"
    isexist=$(docker context ls | grep "$localDockerContextName$")
    if [[ -z $isexist ]]
    then
        docker context create $localDockerContextName  --docker "host=ssh://$BASTION_USERNAME@$BASTION_HOST"
    fi

    printf "\nUsing remote context...\n"
    export DOCKER_CONTEXT=$localDockerContextName

    printf "\nWaiting 3s before checking remote container...\n"
    sleep 3

    printf "\nChecking remote context...\n"
    docker ps
    isexist=$(docker ps --filter "name=$remoteDockerName" --format "{{.Names}}")
    if [[ -z $isexist ]]
    then
        count=1
        while [[ -z $isexist && $count -lt 4 ]]; do
            printf "\nContainer not running... Retrying in 5s"
            sleep 5
            isexist=$(docker ps --filter "name=$remoteDockerName" --format "{{.Names}}")
            ((count=count+1))
        done
    fi
    if [[ -z $isexist ]]
    then
        printf "\nERROR: Remote container $remoteDockerName not running."
        printf "\nUnable to proceed further. Please check merling directory in your bastion host."
        returnOrexit || return 1
    fi


    printf "\nPerforming ssh-add...\n"
    docker exec -idt $remoteDockerName bash -c "cd ~ ; ssh-add ~/.ssh/id_rsa"

    printf "\nStarting tanzu in remote context...\n"
    if [[ -n $MANAGEMENT_CLUSTER_CONFIG_FILE ]]
    then
        # homepath=$(ssh -i $HOME/.ssh/id_rsa $BASTION_USERNAME@$BASTION_HOST 'pwd')
        filename=$(echo $MANAGEMENT_CLUSTER_CONFIG_FILE| rev | awk -v FS='/' '{print $1}' | rev)
        printf "\nLaunching management cluster create using $MANAGEMENT_CLUSTER_CONFIG_FILE...\n"
        docker exec -idt $remoteDockerName bash -c "cd ~ ; tanzu management-cluster create --file $remoteDIR/$filename -v 9"
    else
        printf "\nLaunching management cluster create using UI...\n"
        docker exec -idt $remoteDockerName bash -c "cd ~ ; tanzu management-cluster create --ui -y -v 9 --browser none"
    fi

    chmod 0600 $HOME/.ssh/*
    cp $HOME/.ssh/sshuttleconfig $HOME/.ssh/ssh_config
    mv /etc/ssh/ssh_config /etc/ssh/ssh_config-default
    ln -s $HOME/.ssh/ssh_config /etc/ssh/ssh_config

    export SSHUTTLE=true
    printf "\n\n\n"
    echo "=> Establishing sshuttle with remote $BASTION_USERNAME@$BASTION_HOST...."
    sshuttle --dns --python python2 -D -r $BASTION_USERNAME@$BASTION_HOST 0/0 -x $BASTION_HOST/32 --disable-ipv6 --listen 0.0.0.0:0
    echo "=> DONE."


    printf "\n\n\n Here's your public key in $HOME/.ssh/id_rsa.pub:\n"
    cat $HOME/.ssh/tkg_rsa.pub
    printf "\n\n\nAccess installation UI at http://127.0.0.1:8080"


    containercreated='n'
    containerdeleted='n'
    dobreak='n'
    count=1
    while [[ $dobreak == 'n' && $count -lt 30 ]]; do
        sleep 2m
        printf "\nChecking progres...\n"
        ((count=count+1))
        if [[ $containercreated == 'n' ]]
        then
            printf "Checking bootstrap cluster created..."
            isexist=$(docker container ls | grep "projects.registry.vmware.com/tkg/kind/node" || printf "")
            if [[ -n $isexist ]]
            then
                containercreated='y'
                count=1
                printf "YES"
            else
                printf "NO"
            fi
            printf "\n"
        else
            if [[ $containerdeleted == 'n' ]]
            then
                printf "Checking bootstrap cluster uploaded..."
                dockers=$(docker ps --format "{{.Image}}" || printf "error")
                if [[ -n $dockers && $dockers != "error" ]]
                then
                    isexist=$(printf "$dockers" | grep "projects.registry.vmware.com/tkg/kind/node")
                else
                    isexist='no'
                fi
                if [[ -z $isexist ]]
                then
                    containerdeleted='y'
                    count=1
                    printf "YES"
                else
                    printf "NO"
                fi
                printf "\n"
            fi
        fi
        if [[ $containercreated == 'y' && $containerdeleted == 'y' ]]
        then
            sleep 3
            printf "\nTKG management cluster should have been deployed...\n"
            count=100
            dobreak='y'
        fi
    done



    printf "\n==> TGK management cluster deployed -->> DONE.\n"
    printf "\nWaiting 30s before shuttle shutdown...\n"
    sleep 30

    printf "\nStopping sshuttle...\n"
    sshuttlepid=$(ps aux | grep "/usr/bin/sshuttle --dns" | awk 'FNR == 1 {print $2}')
    kill $sshuttlepid
    printf "==> DONE\n"
    unset SSHUTTLE
    sleep 2



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
    else
        printf "\nGoing to wait for 1m\n"
        sleep 1m
    fi

    if [[ $confirmation == 'n' ]]
    then
        returnOrexit || return 1
    fi

    return 0
}









function downloadTKGFiles () {
    

    printf "\nDownloading management cluster configs from ~/.config/tanzu/tkg/clusterconfigs/...\n"
    cd ~
    mkdir -p $HOME/.config/tanzu/tkg/clusterconfigs
    filename=$(docker exec $remoteDockerName ls -1tc ~/.config/tanzu/tkg/clusterconfigs/ | head -1 || printf "")
    count=1
    while [[ -z $filename && $count -lt 5 ]]; do
        printf "failed getting filename. retrying in 5s...\n"
        sleep 5
        filename=$(docker exec $remoteDockerName ls -1tc ~/.config/tanzu/tkg/clusterconfigs/ | head -1 || printf "")
        ((count=count+1))
    done
    sleep 1
    error='n'
    docker exec $remoteDockerName cat ~/.config/tanzu/tkg/clusterconfigs/$filename > $HOME/.config/tanzu/tkg/clusterconfigs/$filename || error='y'
    count=1
    while [[ $error == 'y' && $count -lt 5 ]]; do
        printf "failed downloading. retrying in 5s...\n"
        sleep 5
        error='n'
        docker exec $remoteDockerName cat ~/.config/tanzu/tkg/clusterconfigs/$filename > $HOME/.config/tanzu/tkg/clusterconfigs/$filename || error='y'
        ((count=count+1))
    done


    sleep 1
    printf "\nDownloading ~/.config/tanzu/config.yaml...\n"
    error='n'
    docker exec $remoteDockerName cat ~/.config/tanzu/config.yaml > $HOME/.config/tanzu/config.yaml || error='y'
    count=1
    while [[ $error == 'y' && $count -lt 5 ]]; do
        printf "failed downloading. retrying in 5s...\n"
        sleep 5
        error='n'
        docker exec $remoteDockerName cat ~/.config/tanzu/config.yaml > $HOME/.config/tanzu/config.yaml || error='y'
        ((count=count+1))
    done

    sleep 1
    printf "\nDownloading ~/.config/tanzu/tkg/cluster-config.yaml...\n"
    error='n'
    docker exec $remoteDockerName cat ~/.config/tanzu/tkg/cluster-config.yaml > $HOME/.config/tanzu/tkg/cluster-config.yaml || error='y'
    count=1
    while [[ $error == 'y' && $count -lt 5 ]]; do
        printf "failed downloading. retrying in 5s...\n"
        sleep 5
        error='n'
        docker exec $remoteDockerName cat ~/.config/tanzu/tkg/cluster-config.yaml > $HOME/.config/tanzu/tkg/cluster-config.yaml || error='y'
        ((count=count+1))
    done

    sleep 1
    printf "\nDownloading ~/.config/tanzu/tkg/features.json...\n"
    error='n'
    docker exec $remoteDockerName cat ~/.config/tanzu/tkg/features.json > $HOME/.config/tanzu/tkg/features.json || error='y'
    count=1
    while [[ $error == 'y' && $count -lt 5 ]]; do
        printf "failed downloading. retrying in 5s...\n"
        sleep 5
        error='n'
        docker exec $remoteDockerName cat ~/.config/tanzu/tkg/features.json > $HOME/.config/tanzu/tkg/features.json || error='y'
        ((count=count+1))
    done

    sleep 1
    printf "\nDownloading ~/.kube/config...\n"
    error='n'
    docker exec $remoteDockerName cat ~/.kube/config > $HOME/.kube/config || error='y'
    count=1
    while [[ $error == 'y' && $count -lt 5 ]]; do
        printf "failed downloading kubeconfig. retrying in 5s...\n"
        sleep 5
        error='n'
        docker exec $remoteDockerName cat ~/.kube/config > $HOME/.kube/config || error='y'
        ((count=count+1))
    done

    mkdir -p ~/.kube-tkg
    sleep 1
    printf "\nDownloading ~/.kube-tkg/config...\n"
    error='n'
    docker exec $remoteDockerName cat ~/.kube-tkg/config > $HOME/.kube-tkg/config || error='y'
    count=1
    while [[ $error == 'y' && $count -lt 5 ]]; do
        printf "failed downloading ~/.kube-tkg/kubeconfig. retrying in 5s...\n"
        sleep 5
        error='n'
        docker exec $remoteDockerName cat ~/.kube-tkg/config > $HOME/.kube-tkg/config || error='y'
        ((count=count+1))
    done

    # scp -r $BASTION_USERNAME@$BASTION_HOST:~/merlin/tkgonvsphere/.config/tanzu/tkg/clusterconfigs ~/.config/tanzu/tkg/
    printf "==> DONE\n"
    sleep 2
    # sleep 10
    # tanzu cluster list
    # tanzu cluster kubeconfig get  --admin

}




function cleanBastion () {

    local confirmation='n'
    while true; do
        read -p "Confirm to continue? [yn] " yn
        case $yn in
            [Yy]* ) confirmation='y'; printf "\nyou confirmed yes\n"; break;;
            [Nn]* ) confirmation='n'; printf "\nyou confirmed no\n"; break;;
            * ) echo "Please answer y when you are ready.";;
        esac
    done

    if [[ $confirmation == 'n' ]]
    then
        returnOrexit || return 1
    fi

    printf "\nCleanup bastion's docker...\n"
    sleep 2
    containerid=$(docker ps -aqf "name=^$remoteDockerName$" || printf "")
    count=1
    while [[ -z $containerid && $count -lt 5 ]]; do
        printf "failed. retrying in 5s...\n"
        sleep 5
        containerid=$(docker ps -aqf "name=^$remoteDockerName$" || printf "")
        ((count=count+1))
    done
    error='n'
    docker container stop $containerid || error='y' 
    count=1
    while [[ $error == 'y' && $count -lt 5 ]]; do
        printf "failed. retrying in 5s...\n"
        sleep 5
        error='n'
        docker container stop $containerid || error='y' 
        ((count=count+1))
    done
    printf "\nStopped container..."
    docker container rm $containerid
    sleep 2
    docker container rm $(docker container ls --all -q)
    printf "\nRemoved container image..."
    sleep 2
    docker volume prune -f
    printf "\nFreeing up space..."
    sleep 2
    docker rmi -f $(docker images -f "dangling=true" -q)
    sleep 2
    docker rmi -f $(docker images -q)
    printf "\nRemoved docker images..."


    unset DOCKER_CONTEXT

    # printf "\n\n"
    # printf "\nDuring the installation process Tanzu CLI created few files in the bastion host under directory ~/merlin of user $BASTION_USERNAME"
    # printf "\nNecessary files are downloaded on your local (this docker container) directory for local connection to tanzu kubernetes grid."
    # printf "\nThus you have copy of the required files in your local so it is safe to delete the remote files."
    # printf "\nHowever, If you have enough space on the bastion host you may choose keep these files on the bastion host, just in case."
    # printf "\nYou may also choose to delete these files."
    # printf "\n\n"
    # isremoveremotefiles='n'
    # while true; do
    #     read -p "Would you like to remove Tanzu CLI files from bastion host? [yn]: " yn
    #     case $yn in
    #         [Yy]* ) isremoveremotefiles='y'; printf "\nyou confirmed yes\n"; break;;
    #         [Nn]* ) printf "\nyou said no.\n"; break;;
    #         * ) echo "Please answer y or n to proceed...";;
    #     esac
    # done
    # if [[ $isremoveremotefiles == 'y' ]]
    # then
    #     printf "\nCleanup bastion's files...\n"
    #     sleep 2
    #     error='n'
    #     docker exec merlintkgonvsphere rm -r ~/.cache/ ~/.config/ ~/.local/ ~/.kube-tkg/ ~/.kube/ || error='y'
    #     count=1
    #     while [[ $error == 'y' && $count -lt 5 ]]; do
    #         printf "failed. retrying in 5s...\n"
    #         sleep 5
    #         error='n'
    #         docker exec merlintkgonvsphere rm -r ~/.cache/ ~/.config/ ~/.local/ ~/.kube-tkg/ ~/.kube/ || error='y'
    #         ((count=count+1))
    #     done
    #     printf "\nRemoved configs and caches files..."
    #     sleep 2
    #     ssh -i $HOME/.ssh/id_rsa $BASTION_USERNAME@$BASTION_HOST 'rm -r ~/merlin/tkgonvsphere'
    #     printf "\nRemoved tkgonvsphere under ~/merlin/..."
    # fi



    printf "\n==> DONE\n"
    printf "\n==> Cleanup process complete....\n"
}





function auto_tkginstall () {
    prechecks
    prepareRemote
    startTKGCreate
    downloadTKGFiles
    cleanBastion
}


# printf "\nStarting sshuttle...\n"
# sshuttle --dns --python python2 -D -r $BASTION_USERNAME@$BASTION_HOST 0/0 -x $BASTION_HOST/32 --disable-ipv6 --listen 0.0.0.0:0
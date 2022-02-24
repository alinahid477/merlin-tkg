#!/bin/bash
remoteDIR="~/merlin/merlin-tkg"
remoteDockerName="merlin-tkg"


docker login -u $1 -p $2
docker build -f $remoteDIR/Dockerfile -t $remoteDockerName $remoteDIR/binaries/ # --build-arg USER_ID=$(id -u) --build-arg GROUP_ID=$(id -g)
homepath=$(pwd)
printf "\nStrating $remoteDockerName...\n"
docker run -td --rm --net=host -v $homepath/merlin/merlin-tkg:/root/ -v /var/run/docker.sock:/var/run/docker.sock --name $remoteDockerName $remoteDockerName
printf "\nDONE...\n"
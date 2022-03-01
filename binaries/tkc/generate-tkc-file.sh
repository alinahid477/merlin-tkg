#!/bin/bash
export $(cat /root/.env | xargs)

templateFilesDIR=$(echo "$HOME/binaries/templates" | xargs)


source $HOME/binaries/scripts/contains-element.sh
source $HOME/binaries/scripts/build-deployment-file.sh
source $HOME/binaries/scripts/extract-and-take-input.sh

generateTKCFile () {
    printf "\n*******Starting TKC wizard*******\n\n"

    unset name
    while [[ -z $name ]]; do
        read -p "Cluster Name: " name
        if [[ -z $name ]]
        then
            printf "empty value is not allowed.\n"
        fi
    done

    printf "\ncreating temporary file...."
    tmpTKCFile=$(echo "/tmp/tkc-$name.yaml" | xargs)
    cp $templateFilesDIR/basetkc.template $tmpTKCFile && printf "ok." || printf "failed"
    printf "\n"

    printf "generate TKC file...\n"
    assembleFile $tmpProfileFile
    printf "\nprofile file generation...COMPLETE.\n"


    printf "\n\n\n"


    extractVariableAndTakeInput $tmpProfileFile
    printf "\nprofile value adjustment...COMPLETE\n"

    printf "\nadding file for confirmation..."
    cp $tmpProfileFile ~/tapconfigs/ && printf "COMPLETE" || printf "FAILED"

    printf "\n\nGenerated profile file: $HOME/tapconfigs/profile-$profilename.yaml\n\n"

    echo "$HOME/tapconfigs/profile-$profilename.yaml" >> $(echo $notifyfile)
}

# generateProfile

# debug

# profilename="debug"
# profiletype="full"
# printf "\ncreating temporary file for profile...."
# tmpProfileFile=$(echo "/tmp/profile-$profilename.yaml" | xargs)
# cp $templateFilesDIR/profile-$profiletype.template $tmpProfileFile && printf "ok." || printf "failed"
# printf "\n"
# buildProfileFile $tmpProfileFile
# end debug
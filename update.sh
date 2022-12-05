#!/bin/bash

mkdir -p ./versions/

version=$1
if [[ $1 == "" ]]; then
  echo "you need to define your version as a argument -> ./update 0.1"
  exit 0
fi
#version=$(cat currentVersion.json | jq ".version")
#echo $version
    
vercomp () {
    arg1=$(echo "$1" | tr -d '"') #remove " from versions
    arg2=$(echo "$2" | tr -d '"')
    if [[ $arg1 == $arg2 ]]
    then
        #echo "=1"
        return 1
    fi
    local IFS=.
    local i ver1=($arg1) ver2=($arg2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]}))
        then
            #echo ">"
            return 2
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]}))
        then
            #echo "<"
            return 0
        fi
    done
    #echo "=2"
    return 1
}

fileExist() {
    #$1 file 
    if [[ -f "$1" ]]; then
        return 1
    fi
    return 0
}

files=($(ls -A versions/ | grep ".json"))
for var in "${files[@]}"
do
    echo "${var}"
    ver=$version
    mapfile -t arr < <(jq -r ".versions | keys" versions/${var})
    unset arr[0]
    unset arr[-1]
    existingVersions=()
    location=$(jq -r ".LOCATION" versions/${var})
    mkdir -p location
    for a in "${arr[@]}"
    do
        a=$(echo "$a" | tr -d ' ' | tr -d ',')
        vercomp $a $version
        comp=$?
        case $comp in
            0) op='<';;
            1) op='=';;
            2) op='>';;
        esac
        if [[ 2 > $comp ]]; then 
            neededVersion=$a
        fi
        file=$location/$(jq -r ".versions.$a.\"FILE-NAME\"" versions/${var})
        fileExist "$file"
        exists=$?
        echo "$a $op $version compvalue $comp file:$file exist:$exists"
        if [[ $exists == 1 ]]
        then
            existingVersions+=$a
        fi
    done


    for (( i=0; i<${#existingVersions[@]}; i++ )); do 
        echo remove check ${#existingVersions[@]} ${existingVersions[i]} $neededVersion
        if [[ ${existingVersions[i]} == $neededVersion ]]; then
            existingVersions=( "${existingVersions[@]:0:$i}" "${existingVersions[@]:$((i + 1))}" )
            i=$((i - 1))
        else 
            location=$(jq -r ".LOCATION" versions/${var})
            file=$location/$(jq -r ".versions.${existingVersions[i]}.\"FILE-NAME\"" versions/${var})
            rm $file
        fi
    done
    location=$(jq -r ".LOCATION" versions/${var})
    file=$location/$(jq -r ".versions.$neededVersion.\"FILE-NAME\"" versions/${var})
    fileExist $file
    if [[ $? == 0 ]]; then
        echo neededversion $neededVersion
        URL=$(jq -r ".versions.$neededVersion.\"URL\"" versions/${var})
        echo get Version: $neededVersion  
        wget $URL -P $location
        echo $oldVersion
    fi
    # do something on $var
done


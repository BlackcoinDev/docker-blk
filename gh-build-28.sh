#!/bin/bash

BASE_DIR=$(dirname $(realpath $0 ))
moreBuilder=${BASE_DIR}/moreBuilder
rm -fr ${moreBuilder}/*

export SYSTYPE=x86_64
export DockerHub=blackcoinorg
export HUBLAB=github
export GITNAME=CoinBlack
export BRANCH=${GIT_CURRENT_BRANCH}
export TZ=Etc/UTC

# tag names
base="${DockerHub}/blackcoin-more-28.4.0-base-${SYSTYPE}:${BRANCH}"
minimal="${DockerHub}/blackcoin-more-minimal-${SYSTYPE}-v28x:${BRANCH}"
ubuntu="${DockerHub}/blackcoin-more-ubuntu-${SYSTYPE}-v28x:${BRANCH}"

sed -i "s|master|${BRANCH}|" ${BASE_DIR}/Dockerfile.minbase
sed -i "s|master|${BRANCH}|" ${BASE_DIR}/Dockerfile.ubase
sed -i "s|FROM .* as build|FROM ${base} as build|" ${BASE_DIR}/Dockerfile.ubuntu

echo "${GITHUB_ENV} = GITHUB_ENV"
echo "DockerHub Account: ${DockerHub}"
echo "Git Account: ${GITNAME}"
echo ${BRANCH}
echo ${SYSTYPE}
echo ${TZ}

# build
# minbase (base using ubuntu)
# ubuntu (package with full ubuntu distro)
docker build -t ${base} --network=host -f ${BASE_DIR}/Dockerfile.minbase ${BASE_DIR}
if [ $? -ne 0 ]; then
    echo "Error building base image" && exit 1
fi
docker build -t ${ubuntu} --network=host -f ${BASE_DIR}/Dockerfile.ubuntu ${BASE_DIR}
if [ $? -ne 0 ]; then
    echo "Error building ubuntu image" && exit 1
fi
docker image push ${ubuntu}
if [ $? -ne 0 ]; then
    echo "Error pushing image" && exit 1
fi


# minimal (only package binaries and scripts)
docker run -itd  --network=host --name base ${base} bash
docker cp base:/parts ${moreBuilder}
cd ${moreBuilder}
tar -c . | docker import - ${minimal} &&  docker image push ${minimal}
if [ $? -ne 0 ]; then
    echo "Error creating and pushing minimal image" && exit 1
fi

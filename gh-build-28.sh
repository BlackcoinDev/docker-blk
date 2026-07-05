#!/bin/bash

BASE_DIR=$(dirname $(realpath $0 ))

export DockerHub=blackcoinorg
export HUBLAB=github
export GITNAME=CoinBlack
export BRANCH=${GIT_CURRENT_BRANCH}
export TZ=Etc/UTC

# tag names (Option A - Unified multi-arch repositories)
base="${DockerHub}/blackcoin-more-28.4.0-base:${BRANCH}"
minimal="${DockerHub}/blackcoin-more-minimal-v28x:${BRANCH}"
ubuntu="${DockerHub}/blackcoin-more-ubuntu-v28x:${BRANCH}"

sed -i "s|master|${BRANCH}|" ${BASE_DIR}/Dockerfile.minbase
sed -i "s|master|${BRANCH}|" ${BASE_DIR}/Dockerfile.ubase
sed -i "s|FROM .* as build|FROM ${base} as build|" ${BASE_DIR}/Dockerfile.ubuntu

echo "DockerHub Account: ${DockerHub}"
echo "Git Account: ${GITNAME}"
echo "Branch/Tag: ${BRANCH}"
echo "Base Image: ${base}"
echo "Ubuntu Image: ${ubuntu}"
echo "Minimal Image: ${minimal}"

# 1. Build and push multi-arch Base image
docker buildx build --platform linux/amd64,linux/arm64 -t ${base} --push -f ${BASE_DIR}/Dockerfile.minbase ${BASE_DIR}
if [ $? -ne 0 ]; then
    echo "Error building base image" && exit 1
fi

# 2. Build and push multi-arch Ubuntu image
docker buildx build --platform linux/amd64,linux/arm64 -t ${ubuntu} --push -f ${BASE_DIR}/Dockerfile.ubuntu ${BASE_DIR}
if [ $? -ne 0 ]; then
    echo "Error building ubuntu image" && exit 1
fi

# 3. Build and push multi-arch Minimal image
docker buildx build --platform linux/amd64,linux/arm64 --build-arg BASE_IMAGE=${base} -t ${minimal} --push -f ${BASE_DIR}/Dockerfile.minimal ${BASE_DIR}
if [ $? -ne 0 ]; then
    echo "Error building minimal image" && exit 1
fi

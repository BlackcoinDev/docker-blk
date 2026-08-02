#!/bin/bash

BASE_DIR=$(dirname $(realpath $0 ))

export DockerHub=${DOCKER_HUB_USER:-blackcoindev}
export HUBLAB=github
export GITNAME=BlackcoinDev
export BRANCH=${GIT_CURRENT_BRANCH}
export TZ=Etc/UTC

# Platform configuration (default: multi-arch)
PLATFORM=${PLATFORM:-"linux/amd64,linux/arm64"}

# Suffix logic to prevent overwriting tags when building native architectures separately
if [[ "${PLATFORM}" == *"linux/amd64"* && "${PLATFORM}" == *"linux/arm64"* ]]; then
	SUFFIX=""
elif [[ "${PLATFORM}" == *"linux/arm64"* ]]; then
	SUFFIX="-arm64"
elif [[ "${PLATFORM}" == *"linux/amd64"* ]]; then
	SUFFIX="-amd64"
else
	SUFFIX=""
fi

# tag names
base="${DockerHub}/blackcoin-more-28.4.0-base:${BRANCH}${SUFFIX}"
minimal="${DockerHub}/blackcoin-more-28.4.0-minimal:${BRANCH}${SUFFIX}"
debian="${DockerHub}/blackcoin-more-28.4.0-debian:${BRANCH}${SUFFIX}"

sed -i "s|master|${BRANCH}|" ${BASE_DIR}/Dockerfile.minbase

echo "DockerHub Account: ${DockerHub}"
echo "Git Account: ${GITNAME}"
echo "Branch/Tag: ${BRANCH}"
echo "Platform: ${PLATFORM}"
echo "Base Image: ${base}"
echo "Debian Image: ${debian}"
echo "Minimal Image: ${minimal}"

# 1. Build and push Base image
docker buildx build --platform ${PLATFORM} -t ${base} --push -f ${BASE_DIR}/Dockerfile.minbase-bdev ${BASE_DIR}
if [ $? -ne 0 ]; then
    echo "Error building base image" && exit 1
fi

# 2. Build and push Debian image
docker buildx build --platform ${PLATFORM} --build-arg BASE_IMAGE=${base} -t ${debian} --push -f ${BASE_DIR}/Dockerfile.debian-bdev ${BASE_DIR}
if [ $? -ne 0 ]; then
    echo "Error building debian image" && exit 1
fi

# 3. Build and push Minimal image
docker buildx build --platform ${PLATFORM} --build-arg BASE_IMAGE=${base} -t ${minimal} --push -f ${BASE_DIR}/Dockerfile.minimal-bdev ${BASE_DIR}
if [ $? -ne 0 ]; then
    echo "Error building minimal image" && exit 1
fi

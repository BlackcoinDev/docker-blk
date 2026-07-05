#!/bin/bash

BASE_DIR=$(dirname $(realpath $0 ))
moreBuilder=${BASE_DIR}/moreBuilder
rm -fr ${moreBuilder}/*

defaultSysType=x86_64
SYSTYPE=`lscpu | head -1 | tr -s ' ' | cut -d ' ' -f2`
if [ ${SYSTYPE} != ${defaultSysType} ]; then
	sed -i "s/defaultSysType=x86_64/defaultSysType=${SYSTYPE}/" $0
	sed -i "s|x86_64|${SYSTYPE}|" ${BASE_DIR}/Dockerfile.debian
	sed -i "s|x86_64|${SYSTYPE}|" $0

fi

# DockerHub Account

defaultDockerHub=blackcoinnl
read -p "What is your DockerHub Account Name? (default: ${defaultDockerHub}): " DockerHub
DockerHub=${DockerHub:-${defaultDockerHub}}
if [ ${DockerHub} != ${defaultDockerHub} ]; then
	sed -i "s/defaultDockerHub=blackcoinnl/defaultDockerHub=${DockerHub}/" $0
	sed -i "s|blackcoinnl|${DockerHub}|" ${BASE_DIR}/Dockerfile.debian
	sed -i "s|blackcoinnl|${DockerHub}|" $0

fi

# Git Account

defaultHubLab=github
read -p "Github or Gitlab? (default: ${defaultHubLab}): " HubLab
HubLab=${HubLab:-${defaultHubLab}}
if [ ${HubLab} != ${defaultHubLab} ]; then
	sed -i "s|defaultHubLab=github|defaultHubLab=${HubLab}|" $0
	sed -i "s|HUBLAB=github|HUBLAB=${HubLab}|" ${BASE_DIR}/Dockerfile.minbase
	sed -i "s|HUBLAB=github|HUBLAB=${HubLab}|" $0
fi

defaultGitName=CoinBlack
read -p "Git account to use? (default: ${defaultGitName}): " Git
Git=${Git:-${defaultGitName}}
if [ ${Git} != ${defaultGitName} ]; then
	sed -i "s|defaultGitName=CoinBlack|defaultGitName=${Git}|" $0
	sed -i "s|GITNAME=CoinBlack|GITNAME=${Git}|" ${BASE_DIR}/Dockerfile.minbase
	sed -i "s|GITNAME=CoinBlack|GITNAME=${Git}|" $0
fi

# Git Branch

defaultBranch=master
read -p "What branch/version? (default: ${defaultBranch}): " BRANCH
BRANCH=${BRANCH:-${defaultBranch}}
if [ ${BRANCH} != ${defaultBranch} ]; then
	sed -i "s|defaultBranch=master|defaultBranch=${BRANCH}|" $0
	sed -i "s|BRANCH=master|BRANCH=${BRANCH}|" ${BASE_DIR}/Dockerfile.minbase
	sed -i "s|master|${BRANCH}|" ${BASE_DIR}/Dockerfile.debian
	sed -i "s|BRANCH=master|BRANCH=${BRANCH}|" $0
	sed -i "s|master|${BRANCH}|" $0
fi

# Headless-only configuration

# timezone
defaultTimezone=Etc/UTC
read -p "What is your timezone? (default: ${defaultTimezone}): " timezone
timezone=${timezone:-${defaultTimezone}}
if [ ${timezone} != ${defaultTimezone} ]; then
	sed -i "s|defaultTimezone=Etc/UTC|defaultTimezone=${timezone}|" $0
	sed -i "s|defaultTimezone=Etc/UTC|${timezone}|" ${BASE_DIR}/Dockerfile.minbase
	sed -i "s|defaultTimezone=Etc/UTC|${timezone}|" ${BASE_DIR}/Dockerfile.debian
fi


echo "DockerHub Account: ${DockerHub}"
echo "Git Account: ${Git}"
echo ${BRANCH}
echo ${SYSTYPE}
echo ${timezone}

# tag names
base="${DockerHub}/blackcoin-more-base-${SYSTYPE}:${BRANCH}"
minimal="${DockerHub}/blackcoin-more-minimal-${SYSTYPE}:${BRANCH}"
debian="${DockerHub}/blackcoin-more-debian-${SYSTYPE}:${BRANCH}"

# build
# minbase (base compiling headless client)
# debian (package with full debian distro)
docker build -t ${base} - --network=host < ${BASE_DIR}/Dockerfile.minbase
docker build -t ${debian} - --network=host < ${BASE_DIR}/Dockerfile.debian
docker image push ${debian}
# minimal (only package binaries and scripts)
docker run -itd  --network=host --name base ${base} bash
docker cp base:/parts ${moreBuilder}
cd ${moreBuilder}
tar -C parts -c . | docker import - ${minimal}
docker image push ${minimal}
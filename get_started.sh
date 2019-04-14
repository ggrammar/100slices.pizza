#!/bin/bash

# I chose Docker for local testing, so you'll need Docker installed.
DOCKER_INSTALLED=`dpkg -l | grep docker`
if [[ -z ${DOCKER_INSTALLED} ]]; then
	echo "Please install docker."
	echo "https://docs.docker.com/install/linux/docker-ce/ubuntu/"
	exit 1
fi

# I chose Ansible for deployment, so you'll need that as well.
ANSIBLE_INSTALLED=`dpkg -l | grep ansible`
if [[ -z ${ANSIBLE_INSTALLED} ]]; then
	echo "Please install Ansible."
	exit 1
fi

# git for pushing code around. 
GIT_INSTALLED=`dpkg -l | grep git`
if [[ -z ${GIT_INSTALLED} ]]; then
	echo "Please install git."
	exit 1
fi

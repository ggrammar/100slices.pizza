#!/bin/bash

# Let's build and test our website.

CONTAINER_NAME='100slices'

echo "Preparing the container with Ansible prerequisites."
docker build --tag ${CONTAINER_NAME} .

# Make sure we clean up any old Docker containers. 
RUNNING_CONTAINERS=`docker ps \
	--all \
	--quiet \
	--filter "name=${CONTAINER_NAME}"`

if [[ ! -z ${RUNNING_CONTAINERS} ]]; then
	# echo "Container is already running."
	# TODO: After this is all in a Dockerfile, just restart the container,
	# since we won't have to re-install everything.
	echo "Killing and removing existing ${CONTAINER_NAME} containers..."
	docker kill ${RUNNING_CONTAINERS} > /dev/null
	docker rm ${RUNNING_CONTAINERS}   > /dev/null
else
	echo "No existing ${CONTAINER_NAME} containers found."
fi


# Launch the local Docker container that will run the website. 
#	8080:80 to get the webserver available locally. 
#	2222:22 to 
#		Ansible needs to be configured to look at localhost:2222
CONTAINER_ID=`docker run \
	--name ${CONTAINER_NAME} \
	--publish 8080:80 \
	--publish 2222:22 \
	--tty \
	--detach \
	${CONTAINER_NAME}`

if [[ $? -ne 0 ]]; then
	echo "Some sort of error launching the container."
	exit 1
else
	echo "Launched ${CONTAINER_NAME} container with ID ${CONTAINER_ID}."
fi

# This is probably a brand new container, so
# TODO: Is there a more graceful way to handle this? This requires saying 'yes'
# each time you spin up a new container. 
ssh-keygen -f ~/.ssh/known_hosts -R "[localhost]:2222"
ssh-keyscan -p 2222 localhost >> ~/.ssh/known_hosts

# Do our Ansible thing to the container. This should be responsible for all
# infrastructure config etc outside of the actual provisioning of the machine.
ansible-playbook \
	--inventory='./infra/hosts.yml' \
	--limit='100slices' \
	./infra/main.yml


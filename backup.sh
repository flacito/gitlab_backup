#!/bin/bash
set -e
source /container/backup.env

# Take the first running instance of a GitLab container in the stack
CONTAINER_NAME=$(docker ps -q -f "name=${DOCKER_STACK_NAME}_${DOCKER_GITLAB_CONTAINER_NAME}" -f "status=running" | sed -e 1b)
set -x
docker exec -t $CONTAINER_NAME gitlab-rake gitlab:backup:create

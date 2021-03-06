#!/bin/bash
set -e
source /container/backup.env

# Take the first running instance of a GitLab container in the stack
CONTAINER_NAME=$(docker ps -q -f "name=${DOCKER_STACK_NAME}_${DOCKER_GITLAB_CONTAINER_NAME}" -f "status=running" | sed -e 1b)

# if curl -s -f  http://${DOCKER_GITLAB_CONTAINER_NAME}:8500/help
  set -x
  docker cp /container/backup.env $CONTAINER_NAME:/backup.env
  docker cp /container/runbackup.sh $CONTAINER_NAME:/runbackup.sh
  docker cp /container/jfrog $CONTAINER_NAME:/jfrog
  docker exec -t $CONTAINER_NAME /runbackup.sh
# then
# fi

# gitlab_backup

This repository contains the configuration for creating a Docker image that can
be used to run GitLab's backup utility in a given running GitLab container. It
is intended to be part of a Docker stack where you point the backup container to
a live GitLab container and periodic backups are taken to the volume. By default
the backup schedule is daily, but you may change this in an environment variable.

## Using the image

This image is pushed to Docker's public registry and it is recommended that you
use the image in a Docker Compose file, probably for use in a Docker Stack. While
you may certainly use in other ways, our documentation only illustrates a Docker
Stack.  You can view all the details of this in the test directory's code.

## Configuration for the container

_Required Container Environment Variables_

* DOCKER_STACK_NAME: the name you give your Docker stack when you start it.
* DOCKER_GITLAB_CONTAINER_NAME: the name of your container for GitLab in your
  Docker compose file.

_Optional_
* CRON_SCHEDULE: the cron schedule to use for determining the periodicity of
  the backup.  By default the container will use daily `0 0 * * *`. Cron is
  [well documented here](https://en.wikipedia.org/wiki/Cron#Overview).

An [example stack configuration](https://gitlab.com/bcb-devops/gitlab_backup/blob/master/test/docker-stack.yml)
that we use to test the image on our CI server can be viewed here.

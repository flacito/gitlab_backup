# gitlab_backup

This repository contains the configuration for creating a Docker image that can
be used to run GitLab's backup utility in a given running GitLab container. It
is intended to be part of a Docker stack where you point the backup container to
a live GitLab container and periodic backups are taken to the volume. By default
the backup schedule is daily, but you may change this in an environment variable.
If you enable it, the backup will be pushed to an Artifactory server as well.

## Using the Image

This image is pushed to Docker's public registry and it is recommended that you
use the image in a Docker Compose file, probably for use in a Docker Stack. While
you may certainly use in other ways, our documentation only illustrates a Docker
Stack.  You can view all the details of this in the test directory's code.

## Configuration for the Container

### Required

Container Environment Variables

* DOCKER_STACK_NAME: the name you give your Docker stack when you start it.
* DOCKER_GITLAB_CONTAINER_NAME: the name of your container for GitLab in your
  Docker compose file.

Docker Secret

* Public key file for encrypting the GitLab secrets file (GitLab backup documentation discusses this at the [beginning here](https://docs.gitlab.com/omnibus/settings/backups.html#separate-configuration-backups-from-application-data)). For example, create it from a file:  `docker secret create {docker stack name}_backup_pub_key {GitLab backup public key file}`

### Optional

Container Environment Variables

* GITLAB_BACKUP_DEPTH: the number of backups to keep on the system. Defaults to 7.
* CRON_SCHEDULE: the cron schedule to use for determining the periodicity of
  the backup.  By default the container will use daily `0 0 * * *`. Cron is
  [well documented here](https://en.wikipedia.org/wiki/Cron#Overview).

* ARTIFACTORY_UPLOAD: indicates that the backup artifacts will be
  uploaded to Artifactory. Defaults to false.
* ARTIFACTORY_PATH: if ARTIFACTORY_UPLOAD is true, this is the path on the Artifactory server that the [JFrog CLI](https://www.jfrog.com/getcli/) will use.
* ARTIFACTORY_API_KEY_PATH: if ARTIFACTORY_UPLOAD is true, this is the API key file path (it is in a file to support Docker secrets), that the [JFrog CLI](https://www.jfrog.com/getcli/) will use.
* ARTIFACTORY_SERVER_URL: if ARTIFACTORY_UPLOAD is true, this is the server URL that the [JFrog CLI](https://www.jfrog.com/getcli/) will use.
* ARTIFACTORY_USE_MAVEN_SNAPSHOT: if ARTIFACTORY_USE_MAVEN_SNAPSHOT is true, the backup process will package the backup, secrets, and key into a tarball and use Maven's snapshot version scheme.  This is useful for automatically deleting old backups from Artifactory.

Docker Secret

* If ARTIFACTORY_UPLOAD is true, create a Docker secret that is the API key string and use it in your Docker stack config. The file path for the secret will then be used on the JFrog CLI calls. For example,  `echo 'your API key string here, not this text' | docker secret create artifactory_api_key -`, then use `/run/secrets/artifactory_api_key` if that is how you are placing the API key secret file in your Docker stack. Then put `/run/secrets/artifactory_api_key` in the `ARTIFACTORY_API_KEY_PATH` environment variable.

An [example stack configuration](https://gitlab.com/bcb-devops/gitlab_backup/blob/master/test/gitlab-stack.yml)
that we use to test the image on our CI server can be viewed here.

set -e

BD=7
if [[ -z "${GITLAB_BACKUP_DEPTH}" ]]; then
  echo "you didn't specify a GITLAB_BACKUP_DEPTH environment variable. Will use the default and keep the latest ${BD} backups."
  GITLAB_BACKUP_DEPTH=$BD
fi

echo "export DOCKER_STACK_NAME=$DOCKER_STACK_NAME" > /container/backup.env
echo "export DOCKER_GITLAB_CONTAINER_NAME=$DOCKER_GITLAB_CONTAINER_NAME" >> /container/backup.env
echo "export GITLAB_BACKUP_DEPTH=$GITLAB_BACKUP_DEPTH" >> /container/backup.env
echo "export ARTIFACTORY_UPLOAD=$ARTIFACTORY_UPLOAD" >> /container/backup.env
echo "export ARTIFACTORY_API_KEY_PATH=$ARTIFACTORY_API_KEY_PATH" >> /container/backup.env
echo "export ARTIFACTORY_SERVER_URL=$ARTIFACTORY_SERVER_URL" >> /container/backup.env
echo "export ARTIFACTORY_PATH=$ARTIFACTORY_PATH" >> /container/backup.env
echo "configured Docker enviornment for GitLab backups"
cat /container/backup.env

CS="0 0 * * *"
if [[ -z "${GITLAB_BACKUP_CRON_SCHEDULE}" ]]; then
  echo "you didn't specify a GITLAB_BACKUP_CRON_SCHEDULE environment variable. Will use the default daily cron schedule: ${CS}."
  GITLAB_BACKUP_CRON_SCHEDULE=$CS
fi
echo "${GITLAB_BACKUP_CRON_SCHEDULE} /bin/sh /container/backup.sh >> /var/log/gitlab_backup.log 2>&1" > /etc/crontabs/root

crond
echo "started cron schedule for GitLab backups"
tail -f /var/log/gitlab_backup.log

set -e

echo "export DOCKER_STACK_NAME=$DOCKER_STACK_NAME" > /container/backup.env
echo "export DOCKER_GITLAB_CONTAINER_NAME=$DOCKER_GITLAB_CONTAINER_NAME" >> /container/backup.env
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

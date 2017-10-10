#!/bin/bash
set -e
set -x

gitlab-rake gitlab:backup:create

GITLAB_BACKUP_NAME=$(ls /var/opt/gitlab/backups/*.tar -Art | tr '\n' '\0' | xargs -0 -n 1 basename | tail -n 1)
CLEAR_KEY_FILE="/tmp/${GITLAB_BACKUP_NAME}_key.bin"
ENC_KEY_FILE="/var/opt/gitlab/backups/${GITLAB_BACKUP_NAME}_key.bin.enc"

openssl rand -base64 32 > ${CLEAR_KEY_FILE}
openssl rsautl -encrypt -inkey /run/secrets/gitlab_backup_pub_key.pem -pubin -in ${CLEAR_KEY_FILE} -out ${ENC_KEY_FILE}
openssl enc -aes-256-cbc -salt -in /etc/gitlab/gitlab-secrets.json -out /var/opt/gitlab/backups/${GITLAB_BACKUP_NAME}_gitlab-secrets.json.enc -pass file:${CLEAR_KEY_FILE}
rm ${CLEAR_KEY_FILE}

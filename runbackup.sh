#!/bin/bash
set -e
set -x

# Run GitLab backup process
gitlab-rake gitlab:backup:create

BACKUP_DIR=/var/opt/gitlab/backups

# Encrypt secrets file and provide key to decrypt
GITLAB_BACKUP_NAME=$(ls ${BACKUP_DIR}/*.tar -Art | tr '\n' '\0' | xargs -0 -n 1 basename | tail -n 1)
CLEAR_KEY_FILE="/tmp/${GITLAB_BACKUP_NAME}_key.bin"
ENC_KEY_FILE="${BACKUP_DIR}/${GITLAB_BACKUP_NAME}_key.bin.enc"
openssl rand -base64 32 > ${CLEAR_KEY_FILE}
openssl rsautl -encrypt -inkey /run/secrets/gitlab_backup_pub_key.pem -pubin -in ${CLEAR_KEY_FILE} -out ${ENC_KEY_FILE}
openssl enc -aes-256-cbc -salt -in /etc/gitlab/gitlab-secrets.json -out ${BACKUP_DIR}/${GITLAB_BACKUP_NAME}_gitlab-secrets.json.enc -pass file:${CLEAR_KEY_FILE}
rm ${CLEAR_KEY_FILE}

# Prune the backups
BD=7
if [[ "${1}" ]]; then
  echo "You specified a GitLab backup depth of ${1} as an argument on the command line."
  BD=$1
fi
echo "backup_depth=${BD}"
GBD=$(($BD+1))

ls -1t ${BACKUP_DIR}/*ee_gitlab_backup.tar | tail -n +${GBD} | while IFS= read -r f; do
  rm -f "$f"
done

ls -1t ${BACKUP_DIR}/*ee_gitlab_backup.tar_key.bin.enc | tail -n +${GBD} | while IFS= read -r f; do
  rm -f "$f"
done

ls -1t ${BACKUP_DIR}/*ee_gitlab_backup.tar_gitlab-secrets.json.enc | tail -n +${GBD} | while IFS= read -r f; do
  rm -f "$f"
done

ls -1tr $BACKUP_DIR

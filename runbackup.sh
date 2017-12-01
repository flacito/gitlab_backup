#!/bin/bash
set -e
set -x

source /backup.env

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
if [[ "${GITLAB_BACKUP_DEPTH}" ]]; then
  echo "You specified a GitLab backup depth of ${GITLAB_BACKUP_DEPTH}."
  BD=$GITLAB_BACKUP_DEPTH
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

# Upload to Artifactory if enabled
if [ "$ARTIFACTORY_UPLOAD" = true ] ; then
  # if ! [ -f /jfrog ]
  # then
  #   curl -fL https://getcli.jfrog.io | sh
  #   mv ./jfrog /jfrog
  # fi

  ARTY_TAR_NAME="gitlab_backup-${GITLAB_BACKUP_NAME}"
  if [ "$ARTIFACTORY_USE_MAVEN_SNAPSHOT" = true ] ; then
    ARTY_TAR_NAME="gitlab_backup.1.0.0-${GITLAB_BACKUP_NAME}-SNAPSHOT.tar"
  fi

  cd ${BACKUP_DIR}
  echo "./${GITLAB_BACKUP_NAME}" > $GITLAB_BACKUP_NAME.files.txt
  echo "./${GITLAB_BACKUP_NAME}_key.bin.enc" >> $GITLAB_BACKUP_NAME.files.txt
  echo "./${GITLAB_BACKUP_NAME}_gitlab-secrets.json.enc" >> $GITLAB_BACKUP_NAME.files.txt

  tar -c -f "${ARTY_TAR_NAME}" -T $GITLAB_BACKUP_NAME.files.txt

  echo "Uploading to Artifactory..."
  /jfrog -v
  /jfrog rt c rt-server --apikey "$(cat $ARTIFACTORY_API_KEY_PATH)" --url "${ARTIFACTORY_SERVER_URL}" --interactive false
  /jfrog rt use rt-server
  /jfrog rt u "./${ARTY_TAR_NAME}" $ARTIFACTORY_PATH
  /jfrog rt c --interactive false delete rt-server
  echo "...upload to Artifactory complete. ${GITLAB_BACKUP_NAME} files now in  ${ARTIFACTORY_PATH}."
  rm "${ARTY_TAR_NAME}"
fi

ls -1tr $BACKUP_DIR

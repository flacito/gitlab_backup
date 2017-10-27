variable "docker_stack_name" { default = "testglback" }
variable "gitlab_backup_priv_key_file" { default = "~/.gitlab/id_rsa.pem" }
variable "gitlab_backup_pub_key_file" { default = "~/.gitlab/id_rsa.pub.pem" }

resource "null_resource" "docker_build" {

    provisioner "local-exec" {
      command = "docker build -t localtest/gitlab_backup:latest ../"
    }

    provisioner "local-exec" {
      command = "docker rmi localtest/gitlab_backup:latest"
      when = "destroy"
    }

}

resource "null_resource" "docker_swarm" {

    provisioner "local-exec" {
      command = "docker swarm init"
    }

    provisioner "local-exec" {
      command = "docker swarm leave --force"
      when = "destroy"
    }

}

resource "null_resource" "docker_secrets" {

    provisioner "local-exec" {
      command = <<EOF
        docker secret create gitlab_backup_pub_key ${var.gitlab_backup_pub_key_file}
EOF
    }

    provisioner "local-exec" {
      command = <<EOF
        docker secret rm gitlab_backup_pub_key
EOF
      when = "destroy"
    }

        depends_on = ["null_resource.docker_swarm"]
}

resource "null_resource" "docker_stack" {

    provisioner "local-exec" {
      command = "docker stack deploy -c docker-stack.yml ${var.docker_stack_name}"
    }

    provisioner "local-exec" {
      command = <<EOF
        docker stack rm ${var.docker_stack_name}
        sleep 15
        docker volume rm -f ${var.docker_stack_name}_gitlab_backup
EOF
      when = "destroy"
    }

    depends_on = [ "null_resource.docker_swarm", "null_resource.docker_build", "null_resource.docker_secrets" ]
}

resource "null_resource" "testit" {

  provisioner "local-exec" {
    command = <<EOF
      counter=1
      until curl -s -f  http://localhost:8500/help
      do
        printf 'gitlab not online yet, waiting...'
        sleep 15
        counter=$((counter+5))

        if [ "$counter" -gt "600" ]
        then
          printf 'GitLab failed to come online in under 10 minutes. Check your Docker logs.'
          exit -1
          break
        fi
      done

      CONTID=$(docker ps -qf "name=${var.docker_stack_name}_gitlab" -f "status=running")
      echo "CONTID=$${CONTID}"

      echo "GitLab backup container $${CONTID} online. Sleeping 4 minutes to wait for backup depth to fill."
      sleep 240
      mkdir -p ./.test
      docker cp $CONTID:/var/opt/gitlab/backups ./.test
      set -e
      set -x
      ls ./.test/backups/*.tar
      printf 'GitLab has backups!'

      # Make sure our GITLAB_BACKUP_DEPTH is being honored
      ACTUAL_DEPTH=$(ls -1 ./.test/backups/*.tar | wc -l | xargs)
      if [[ $ACTUAL_DEPTH -ne 2 ]]
      then
        echo "Error. File depth is incorrect for backups.  It should be 2 but is $${ACTUAL_DEPTH}."
        exit -1
      fi

      # Make sure our backups are indeed valid
      GITLAB_BACKUP_FILE_LISTING=$(ls -Art ./.test/backups/*.tar | tr '\n' '\0' | xargs -0 -n 1 | tail -n 1)
      GITLAB_BACKUP_NAME="$${GITLAB_BACKUP_FILE_LISTING##*/}"
      echo "Testing $${GITLAB_BACKUP_NAME}"
      CLEAR_KEY_FILE="./.test/backups/$${GITLAB_BACKUP_NAME}_key.bin"
      ENC_KEY_FILE="./.test/backups/$${GITLAB_BACKUP_NAME}_key.bin.enc"

      openssl rsautl -decrypt -inkey ${var.gitlab_backup_priv_key_file} -in $${ENC_KEY_FILE} -out $${CLEAR_KEY_FILE}
      openssl enc -d -aes-256-cbc -in ./.test/backups/$${GITLAB_BACKUP_NAME}_gitlab-secrets.json.enc -out ./.test/backups/$${GITLAB_BACKUP_NAME}_gitlab-secrets.json -pass file:$${CLEAR_KEY_FILE}

      docker exec $CONTID cat /etc/gitlab/gitlab-secrets.json > ./.test/backups/$${GITLAB_BACKUP_NAME}_gitlab-secrets.orig.json
      diff ./.test/backups/$${GITLAB_BACKUP_NAME}_gitlab-secrets.json ./.test/backups/$${GITLAB_BACKUP_NAME}_gitlab-secrets.orig.json
EOF
  }

  provisioner "local-exec" {
    command = <<EOF
      rm -Rf ./.test
EOF
    when = "destroy"
  }

    depends_on = [ "null_resource.docker_stack" ]
}

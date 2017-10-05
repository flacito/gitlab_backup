variable docker_stack_name { default = "testglback" }

resource "null_resource" "docker_build" {

    provisioner "local-exec" {
      command = "docker build -t postgresbup ../"
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

    depends_on = [ "null_resource.docker_swarm", "null_resource.docker_build" ]
}

resource "null_resource" "testit" {

  provisioner "local-exec" {
    command = <<EOF
      counter=1
      until curl -s -f  http://localhost:8500/help >/dev/null
      do
        printf 'gitlab not online yet, sleeping 5 seconds...'
        sleep 5
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

      echo "GitLab backup container $${CONTID} online. Sleeping 65 seconds to wait for a backup to take place."
      # sleep 65
      mkdir -p ./.test
      docker cp $CONTID:/var/opt/gitlab/backups ./.test
      set -e
      ls ./.test/backups/*.tar
      printf 'GitLab has backups!'
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

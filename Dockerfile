FROM docker
MAINTAINER  btwebb@gmail.com

RUN mkdir /container
RUN mkdir /backup
COPY entry_point.sh /container/entry_point.sh
COPY backup.sh /container/backup.sh
COPY runbackup.sh /container/runbackup.sh

RUN apk update && apk add curl
RUN curl -fL https://getcli.jfrog.io | sh && mv ./jfrog /container/jfrog

RUN echo "/var/log/gitlab_backup.log: GitLab backup log to follow" > /var/log/gitlab_backup.log

CMD /container/entry_point.sh

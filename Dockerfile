FROM docker
MAINTAINER  btwebb@gmail.com

RUN mkdir /container
COPY entry_point.sh /container/entry_point.sh
COPY backup.sh /container/backup.sh
COPY runbackup.sh /container/runbackup.sh
RUN mkdir /backup

RUN echo "/var/log/gitlab_backup.log: GitLab backup log to follow" > /var/log/gitlab_backup.log

CMD /container/entry_point.sh

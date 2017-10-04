FROM docker
MAINTAINER  btwebb@gmail.com

RUN mkdir /container
COPY entry_point.sh /container/entry_point.sh
COPY backup.sh /container/backup.sh
RUN mkdir /backup

RUN echo "Log file for GitLab backups" > /var/log/gitlab_backup.log

CMD /container/entry_point.sh

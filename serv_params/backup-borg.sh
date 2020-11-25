#!/bin/bash

LOCKFILE=/tmp/lockfile
if [ -e ${LOCKFILE} ] && kill -0 `cat ${LOCKFILE}`; then
    echo "Сервис уже работает!"
    exit
fi

trap "rm -f ${LOCKFILE}; exit" INT TERM EXIT
echo $$ > ${LOCKFILE}


BACKUP_HOST='192.168.10.11'
BACKUP_USER='vagrant'
BACKUP_REPO=myrepo
LOG=/var/log/backup_borg.log

export BORG_PASSPHRASE='passphrase'

borg create \
  --stats --list --debug --progress \
  ${BACKUP_USER}@${BACKUP_HOST}:${BACKUP_REPO}::"etc-server-{now:%Y-%m-%d_%H:%M:%S}" \
  /etc 2>> ${LOG}


borg prune \
  -v --list \
  ${BACKUP_USER}@${BACKUP_HOST}:${BACKUP_REPO} \
  --keep-daily=30 \
  --keep-monthly=2 2>> ${LOG}

rm -f ${LOCKFILE}

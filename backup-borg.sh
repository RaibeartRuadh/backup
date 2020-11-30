#!/bin/bash

LOCKFILE=/tmp/lockfile
if [ -e ${LOCKFILE} ] && kill -0 `cat ${LOCKFILE}`; then
    echo "Service already working!"
    exit
fi

trap "rm -f ${LOCKFILE}; exit" INT TERM EXIT
echo $$ > ${LOCKFILE}


BACKUP_HOST='192.168.10.11'
BACKUP_USER='borg'
BACKUP_REPO=$(hostname)-etc

echo $BACKUP_REPO


borg create \
  --info --stats --progress --log-json \
  ${BACKUP_USER}@${BACKUP_HOST}:${BACKUP_REPO}::"etc-{now:%Y-%m-%d_%H:%M:%S}" \
  /etc \
  2>>/var/log/borgbackup.log



borg prune \
  -v --list \
  ${BACKUP_USER}@${BACKUP_HOST}:${BACKUP_REPO} \
  --keep-within 1m \
  --keep-monthly 3 


rm -f ${LOCKFILE}

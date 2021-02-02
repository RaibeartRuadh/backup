#!/bin/bash
# temporary lock - лок на случай повторного запуска
LOCKFILE=/tmp/lockfile
if [ -e ${LOCKFILE} ] && kill -0 `cat ${LOCKFILE}`; then
    echo "Service already working!"
    exit
fi

trap "rm -f ${LOCKFILE}; exit" INT TERM EXIT
echo $$ > ${LOCKFILE}

# environment - параметры окружения
BACKUP_HOST='192.168.10.11'
BACKUP_USER='borg'
BACKUP_REPO='/var/backup'
LOG=/var/log/backup_borg.log
export BORG_PASSPHRASE='derparol'

echo $BACKUP_REPO

# backup create params - создание резервных записей
borg create \
  --stats --list --debug --progress \
  ${BACKUP_USER}@${BACKUP_HOST}:${BACKUP_REPO}::"var-backup-{now:%Y-%m-%d_%H:%M:%S}" \
  /etc 2>> ${LOG}


# delete elder records - удаление резервных записей
borg prune \
  -v --list \
  ${BACKUP_USER}@${BACKUP_HOST}:${BACKUP_REPO} \
  --keep-within 1m \
  --keep-monthly 3 

# remove lock - удаляем лок
rm -f ${LOCKFILE}



#!/bin/bash
# лок на случай повторного запуска
LOCKFILE=/tmp/lockfile
if [ -e ${LOCKFILE} ] && kill -0 `cat ${LOCKFILE}`; then
    echo "Service already working!"
    exit
fi

trap "rm -f ${LOCKFILE}; exit" INT TERM EXIT
echo $$ > ${LOCKFILE}

# параметры окружения
BACKUP_HOST='192.168.10.11'
BACKUP_USER='borg'
BACKUP_REPO=$(hostname)-etc
LOG=/var/log/backup_borg.log
export BORG_PASSPHRASE='derparol'

echo $BACKUP_REPO

# создание резервных записей
borg create \
  --stats --list --debug --progress \
  ${BACKUP_USER}@${BACKUP_HOST}:${BACKUP_REPO}::"etc-server-{now:%Y-%m-%d_%H:%M:%S}" \
  /etc 2>> ${LOG}


# удаление резервных записей
borg prune \
  -v --list \
  ${BACKUP_USER}@${BACKUP_HOST}:${BACKUP_REPO} \
  --keep-within 1m \
  --keep-monthly 3 

# удаляем лок
rm -f ${LOCKFILE}



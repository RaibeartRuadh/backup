# Настраиваем бэкапы
Настроить стенд Vagrant с двумя виртуальными машинами: backup_server и client

Настроить удаленный бекап каталога /etc c сервера client при помощи borgbackup. Резервные копии должны соответствовать следующим критериям:

- Директория для резервных копий /var/backup. Это должна быть отдельная точка монтирования. В данном случае для демонстрации размер не принципиален, достаточно будет и 2GB.
- Репозиторий дле резервных копий должен быть зашифрован ключом или паролем - на ваше усмотрение
- Имя бекапа должно содержать информацию о времени снятия бекапа
- Глубина бекапа должна быть год, хранить можно по последней копии на конец месяца, кроме последних трех. Последние три месяца должны содержать копии на каждый день. Т.е. должна быть правильно настроена политика удаления старых бэкапов
- Резервная копия снимается каждые 5 минут. Такой частый запуск в целях демонстрации.
- Написан скрипт для снятия резервных копий. Скрипт запускается из соответствующей Cron джобы, либо systemd timer-а - на ваше усмотрение.
- Настроено логирование процесса бекапа. Для упрощения можно весь вывод перенаправлять в logger с соответствующим тегом. Если настроите не в syslog, то обязательна ротация логов

Запустите стенд на 30 минут. Убедитесь что резервные копии снимаются. Остановите бекап, удалите (или переместите) директорию /etc и восстановите ее из бекапа. Для сдачи домашнего задания ожидаем настроенные стенд, логи процесса бэкапа и описание процесса восстановления.


Исполнение.
Делим задачу на несколько этапов.
Нужно 2 машины - server и backup

1. Запускаем стенды:
- $ vagrant up

Инициализация borg включает использование шифрования по blake2, что выгоднее в производительности.
(материалы: https://borgbackup.readthedocs.io/en/stable/usage/init.html)

- $ BORG_PASSPHRASE="derparol" borg init --encryption=repokey-blake2 borg@192.168.10.11:server-etc/

При настроенном шифровании passphrase будет запрашиваться каждый раз при запуске процедуры бэкапа. Поэтому для автоматизации бэкапа в нашем скрипте одним из способов является передача passphrase в переменную окружения BORG_PASSPHRASE: export BORG_PASSPHRASE='derparol'.

2. Проверяем скрипт для задачи
- Скрипт уже скопирован в директорию /opt/backup-borg.sh и готов к использованию
- Проверим содержимое:

#!/bin/bash

# Блокирование повторных запусков на случай работы скрипта.
LOCKFILE=/tmp/lockfile
if [ -e ${LOCKFILE} ] && kill -0 `cat ${LOCKFILE}`; then
    echo "Сервис уже работает!"
    exit
fi
# удаление блокировки при завершении
trap "rm -f ${LOCKFILE}; exit" INT TERM EXIT
echo $$ > ${LOCKFILE}

# параметры объекта бэкапирования
# IP address хоста бэкапирования
BACKUP_HOST='192.168.10.11'
# user, под который у нас сертификат
BACKUP_USER='borg'
# название репозитория (указанный при инициализации)
BACKUP_REPO=$(hostname)-etc
# Перенаправляем логи borg в наш файл 
LOG=/var/log/backup_borg.log
# Передача "парольной фразы"
export BORG_PASSPHRASE='derparol'
# Параметры бэкапирования

borg create \
  --stats --list --debug --progress \
  ${BACKUP_USER}@${BACKUP_HOST}:${BACKUP_REPO}::"etc-server-{now:%Y-%m-%d_%H:%M:%S}" \
  /etc 2>> ${LOG}

# Параметры очищения архивов превышающих временное значение
# В данном ДЗ определено хранить бэкапы за последние 30 дней и по одному за предыдущие два месяца
borg prune \
  -v --list \
  ${BACKUP_USER}@${BACKUP_HOST}:${BACKUP_REPO} \
  --keep-within 1m \
  --keep-monthly 3 

rm -f ${LOCKFILE}

- Выполняем скрипт вручную, чтобы проверить работу
- Проверяем журнал

$ cat /var/log/backup_borg.log 

3. Автоматизация бэкапирование

- На хосте сервер созданы два юнита
- юнит-таймер и юнит-сервис с типом oneshot, вызывающий наш скрипт

Конфигурация таймера
Расположение  /etc/systemd/system/backup-borg.timer

[Unit]
Description=Сервис резервирования - таймер

[Timer]
OnBootSec=300
OnUnitActiveSec=300
Unit=backup-borg.service

[Install]
WantedBy=multi-user.target

Конфигурация сервиса
Расположение /etc/systemd/system/backup-borg.service

[Unit]
Description=Служба выполнения резервирования Borg
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
ExecStart=/opt/backup-borg.sh

4. Проверим работу.
Создадим директорию с файлами на хосте server

- $ mkdir /etc/fortest
- $ touch /etc/fortest/file{01..10}
- $ ls -l /etc/fortest/

- После отработки скрипта снимем логи:

5. Восстановление из бэкапа






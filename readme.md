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
- стенды отрабтают частично. Часть действий выполним вручную

2. Выпуск ssh-ключа (server)
- На хосте server выполнить:
- Повысить привелегии:
- $ sudo -i
- выпустим shh-ключ
- $ ssh-keygen
- место хранение пусть будет по-умолчанию
- при создании ключа passphrase не указывать
- После создания ключа, выведите содержимое публичного ключа и сохраните его
- $ cat /root/.ssh/id_rsa.pub 
Пример вывода:

ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDFJbL/cEQAwm/Vzu70Xf2J5+tkqIDRFuq3MbxOAwzZYEq6Jayb3EIH1ZQ/7fEUpmbEvxQaSVYGgtqHaTe5ISkNUjCsGMmhud3ALY9APzCl4LUGSL6z0WZ1sv1qPJy6tuguKh1TMK7ZxXPbq8dEYBUFqSuijSkeGEKYI39a1PZmuvUdhF4qsrgjcbH4evhX1PdsXSD0vrUk/uS1emUjktDQXAwmVXDCMR2TjrZRykgrdV/j9GFewXLic7D1vyD8qyI1rOft/3Zu11k1msJ+5TcJsFtpwy+/EdVdGnQZTL95DDRp7MmeBT1fZZL0QZcbF3W3YeToLG7AdnubJHPOvpX3 root@server

4. Установка ssh-ключа (backup)

- Перейти на хост backup
- проверить, что есть директория /root/.ssh
$ ls /root/.ssh
- при отстуствии директории - создать ее 
- $ mkdir -p /root/.ssh
- Прописываем публичный ключ:
Пример:
- $ echo ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDFJbL/cEQAwm/Vzu70Xf2J5+tkqIDRFuq3MbxOAwzZYEq6Jayb3EIH1ZQ/7fEUpmbEvxQaSVYGgtqHaTe5ISkNUjCsGMmhud3ALY9APzCl4LUGSL6z0WZ1sv1qPJy6tuguKh1TMK7ZxXPbq8dEYBUFqSuijSkeGEKYI39a1PZmuvUdhF4qsrgjcbH4evhX1PdsXSD0vrUk/uS1emUjktDQXAwmVXDCMR2TjrZRykgrdV/j9GFewXLic7D1vyD8qyI1rOft/3Zu11k1msJ+5TcJsFtpwy+/EdVdGnQZTL95DDRp7MmeBT1fZZL0QZcbF3W3YeToLG7AdnubJHPOvpX3 root@server >> /root/.ssh/authorized_keys

5. Проверим, что мы можем зайти по ключу.

- перейти на хост server и выполнить:
- $ ssh root@192.168.10.11
- Подтвердить подключение, введя yes
После ввода контрольного слова, вы попадаете на хост server

             >> Last login: Mon Nov 23 10:59:19 2020 from 10.0.2.2
             [root@backup ~]$

==================================================================
6. Устанавливаем borgbackup на хостах server и backup
Последний стабильный релиз 1.1.14

$ sudo curl -L https://github.com/borgbackup/borg/releases/download/1.1.14/borg-linux64 -o /usr/bin/borg
$ sudo chmod +x /usr/bin/borg


==================================================================
7. Выполняем инициализацию репозитория borg с поддержкой шифрования по алгоритму blake2  на хосте server
(материалы: https://borgbackup.readthedocs.io/en/stable/usage/init.html)

- $ borg init --encryption=repokey-blake2 root@192.168.10.11:myrepo
При инициализации несколько раз вводим контрольное слово - passphrase. Ключ шифрования после инициализации репозитория будет храниться на хосте backup в файле <REPO_DIR>/config:
При настроенном шифровании passphrase будет запрашиваться каждый раз при запуске процедуры бэкапа. Поэтому для автоматизации бэкапа в нашем скрипте одним из способов является передача passphrase в переменную окружения BORG_PASSPHRASE: export BORG_PASSPHRASE='passphrase'.

8. Проверяем скрипт для задачи
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
# IP address
BACKUP_HOST='192.168.10.11'
# user, под который у нас сертификат
BACKUP_USER='root'
# название репозитория (указанный при инициализации)
BACKUP_REPO=myrepo
# Перенаправляем логи borg в наш файл 
LOG=/var/log/backup_borg.log

# Передача "парольной фразы"
export BORG_PASSPHRASE='passphrase'
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
  --keep-daily=30 \
  --keep-monthly=2 2>> ${LOG}

rm -f ${LOCKFILE}

- Выполняем скрипт вручную, чтобы проверить работу
- Проверяем журнал

$ cat /var/log/backup_borg.log 

9. Автоматизируем бэкапирование

- На хосте сервер созданы два юнита
- юнит-таймер и юнит-сервис с типом oneshot, вызывающий наш скрипт

Конфигурация таймера
Расположение  /etc/systemd/system/backup-borg.timer

[Unit]
Description=Сервис резервирования - таймер

[Timer]
OnBootSec=300
OnUnitActiveSec=1h
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


10. Проверим работу.
Создадим директорию с файлами на хосте server

$ mkdir /etc/fortest
$ touch /etc/fortest/file{01..10}
$ ls -l /etc/fortest/

Запускаем службы
- sudo systemctl daemon-reload
- sudo systemctl enable --now backup-borg.timer
- sudo systemctl enable --now backup-borg.service


- После отработки скрипта снимем логи:

12. Восстановление из бэкапа






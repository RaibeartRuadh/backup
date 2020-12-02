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
1. Нужно 2 хоста - server и backup. На на хосте server необходимо примонтировать диск объемом не менее 2GB в /var/backup
2. Обеспечение связи через ssh ключ
3. Установка пакетов
4. Нужен скрипт на свнятие резервных копий
5. Нужен механизм запуска скприта
6. Пакет борг должен быть настроен с ключевой фразой или шифрованием
7. Логи перенаправлять в логгер
8. Ротация логов

Исполнение:

1. Тут пришлось помучаться. Наверное потому, что с вагрантом знаком еще не так много и его ошибки не всегда очевидны. После плясок с бубном всё удалось. Поднимается хост backup, с дополнительным диском, в системе как /dev/sdb
Монтируем по ходу через скрипт server.sh:
      
      #!/bin/sh
      mkdir /var/backup
      sudo mkfs.xfs /dev/sdb
      sudo mount /dev/sdb /var/backup

2. Решается через генерацию скрипта ssh-keygen. Публичный ключ в id_rsa.pub выгружается во внешнюю директорию ssh. Это выполняется на этапе прохода playbook ansible для хоста server. Затем в этапе выполнения playbook для хоста backup мы считываем и помещаем этот ключ в /root/.ssh/known_hosts.
3. Через playbook'и playbackup.yml и playserver.yml. Причем в playbackup.yml присутствует часть для отработки на хосте server. Возможная альтернатива - единый playbook.
4. Простая часть, так как есть куча примеров. Готовый скрипт кладется на хость server.

        #!/bin/bash
        #- Блокирование повторных запусков на случай работы скрипта.
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
        BACKUP_USER='borg'
        BACKUP_REPO='/var/backup'
        LOG=/var/log/backup_borg.log
        export BORG_PASSPHRASE='derparol'
        
        # Параметры бэкапирования
        borg create \
          --stats --list --debug --progress \
          ${BACKUP_USER}@${BACKUP_HOST}:${BACKUP_REPO}::"var-backup--{now:%Y-%m-%d_%H:%M:%S}" \
          /etc 2>> ${LOG}
        
        # Параметры очищения архивов превышающих временное значение
        # В данном ДЗ определено хранить бэкапы за последние 30 дней и по одному за предыдущие два месяца
        borg prune \
          -v --list \
          ${BACKUP_USER}@${BACKUP_HOST}:${BACKUP_REPO} \
          --keep-daily=30 \
          --keep-monthly=2 2>> ${LOG}
        
        rm -f ${LOCKFILE}

5. Регулярный запуск скрипта обеспечивается юнитами timer и service. 

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
        ExecStart=/home/vagrant/backup-borg.sh

6. Для обуспечения безопасности используется алгоритм шифрование blake2 как эффективный и менее затратный. Алгоритм указывается при инициализации borg

7. Логи borg перехватываются и направляются в директорию /var/log/backup_borg.log. 
8. Для ротации логов было добавлено правило в logrotate для borg

# Запуск стенда:
    
    $ vagrant up

После отработки, подлючаемся к хосту server

$ vagrant ssh server

Переходим в директорию /home/vagrant (вы уже в ней по умолчанию, но для порядка надо указать)
Проверяем работу скрипта

- Создаем директорию в /etc

      $ mkdir test && cd test

- Создаем набор пустых файлов

      $ touch file{01..10}

- Инициируем бэкап

      $ bash /home/vagrant/backup-borg.sh

- Удаляем наши файлы

      $ rm -rf test

- При необходимости можно получить информацию о бэкапах.
      
      $ BORG_PASSPHRASE="derparol" borg list borg@192.168.10.11:/var/backup

- Восстанавливаем бэкап, используя последнюю по дате запись
      
      $ BORG_PASSPHRASE="derparol" borg extract ssh://borg@192.168.10.11/var/backup::var-backup-2020-12-02_17:56:54

- Проверяем директорию.
- Наши удаленные файлы успешно воссстановлены!


Материалы:
1. https://community.hetzner.com/tutorials/install-and-configure-borgbackup/ru?title=BorgBackup/ru
2. https://borgbackup.readthedocs.io/en/stable/usage/init.html


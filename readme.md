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
Поднять через vagrant

На server выгружаем бинарный файл borg и разрешаем быть исполняемым
$ sudo curl -L https://github.com/borgbackup/borg/releases/download/1.1.13/borg-linux64 -o /usr/bin/borg
$ sudo chmod +x /usr/bin/borg

Этап 1 - связываем машины через сертификат на пользователя borg

Переходим на хост server
$ vagrant ssh-config > vagrant-ssh; ssh -F vagrant-ssh server

Генерируем SHH-ключ
$ ssh-keygen
- используем директорию для сохранения приватного и публичного ключа /home/vagrant
- используем passphrase - passphrase

$ cat /home/vagrant/id_rsa.pub
вывод:
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDbaHQGvlJ1qhnbK8sQ8kRn9kMg8SH3Foqm34JIn+9pwjYI6hFr7rP1O7VqdrqA4LhT+e53mfTuorP1zIyESrebQ1URNiY6WtXnJxAGrEALCUA+r3vy0Tm+blPQSH5bi1cXcUgsg5Msx4u82JLFRjjgpknJgyYi1OjOj8NrqejeZs2MWrkH9qTHBfrP8QAzE/hv2wUM1RjvNChtay3H0P+UatLAbbcsUu0iPLu2njuQnkKgq3j9HXBd6emc3pXwneL3sWmlezFOxP/CWWpfSBkPU9Yw/6n67FBcokdjhtYo9kC59W8WH7twp9sxQnQtyq70yYtPGD6o8PW0dfnoHyux root@server

Переходим на хост backup
$ vagrant ssh-config > vagrant-ssh; ssh -F vagrant-ssh backup

Устанавливаем публичный ключ на хост backup в ~borg/.ssh/authorized_keys

$ mkdir /home/borg/.ssh
$ echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDbaHQGvlJ1qhnbK8sQ8kRn9kMg8SH3Foqm34JIn+9pwjYI6hFr7rP1O7VqdrqA4LhT+e53mfTuorP1zIyESrebQ1URNiY6WtXnJxAGrEALCUA+r3vy0Tm+blPQSH5bi1cXcUgsg5Msx4u82JLFRjjgpknJgyYi1OjOj8NrqejeZs2MWrkH9qTHBfrP8QAzE/hv2wUM1RjvNChtay3H0P+UatLAbbcsUu0iPLu2njuQnkKgq3j9HXBd6emc3pXwneL3sWmlezFOxP/CWWpfSBkPU9Yw/6n67FBcokdjhtYo9kC59W8WH7twp9sxQnQtyq70yYtPGD6o8PW0dfnoHyux root@server" > /home/borg/.ssh/authorized_keys
$ chown -R borg:borg /home/borg/.ssh


Переходим на хост server
$ vagrant ssh-config > vagrant-ssh; ssh -F vagrant-ssh server

2. Этап ставим репозиторий и настраиваем шифрование

Инициируем репозиторий на хосте backup c именем etcrepo и шифрованием

$ borg init --encryption=repokey-blake2 borg@192.168.10.11:EtcRepo



3. этап. определяем логирование


4. этап Правила формирования бэкапа + архив





















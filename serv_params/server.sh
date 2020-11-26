#!/bin/bash
sudo mkdir /var/backup
sudo mkfs.xfs /dev/sdb
sudo mount /dev/sdb /var/backup
sudo BORG_PASSPHRASE="derparol" borg init --encryption=repokey-blake2 /var/backup

#borg init --encryption=repokey-blake2 root@192.168.10.11:myrepo



#!/bin/sh
sudo BORG_PASSPHRASE="derparol" borg init --encryption=repokey-blake2 borg@192.168.10.11:/var/backup/

#/var/backup

#!/bin/bash
chmod 600 /home/vagrant/private_key
chown root /home/vagrant/private_key
sudo BORG_PASSPHRASE="derparol" \
BORG_RSH="ssh -o 'StrictHostKeyChecking=no' -i /home/vagrant/private_key" \
borg create -v --stats root@192.168.10.10:/var/backup::'{now:%Y-%m-%d-%H-%M}' /etc \
2>&1 | logger &


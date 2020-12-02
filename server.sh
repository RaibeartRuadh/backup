#!/bin/sh
mkdir /var/backup
sudo mkfs.xfs /dev/sdb
sudo mount /dev/sdb /var/backup


#!/bin/bash

# This remove mariadb completely so we can keep testing mariadb.setup.sh.
# No arguments, no remorse. Just kill it.

# remove mariadb
sudo /etc/init.d/mysql stop
sudo apt-get -y remove --purge 'mariadb*'
sudo apt-get -y clean
sudo apt-get -y autoremove

#this is important. If you don't get rid of the old dbs, they will not get overwritten.
sudo rm -r /var/lib/mysql/*

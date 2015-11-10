#!/bin/bash

# This remove mariadb completely so we can keep testing mariadb.setup.sh.
# No arguments, no remorse. Just kill it.

# remove mariadb
sudo /etc/init.d/mysql stop
sudo apt-get -y remove --purge 'mariadb*'
sudo apt-get -y clean
sudo apt-get -y autoremove
sudo rm -r /var/lib/mysql/*

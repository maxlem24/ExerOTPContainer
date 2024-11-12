#!/bin/bash
#Derniere modification le : 16/11/2020 22:42
#Par : Laurent ASSELIN

#mise à jour logicielle

#Verification de la Signature
/usr/local/bin/maj_verify $1
if [ $? -ne 0 ]; then
    echo "Corrupted signature"
	sudo rm -rf /var/www/tmp/*
    exit 84
fi

#unzip
unzip -q $1 -d /var/www/tmp
if [ $? -ne 0 ]; then
    echo "fail 5"
	sudo rm -rf /var/www/tmp/*
    exit 84
fi

cd /var/www/tmp/
chmod +x update_it.sh
sudo ./update_it.sh

#Nettoyage
sudo rm -rf /var/www/tmp/*

#!/bin/bash
#Derniere modification le : 03/06/2022
#Par : Laurent ASSELIN

#Nettoyage des logs
rm /var/log/*.gz
rm /var/log/*.1
rm /var/log/apt/*
rm /var/log/mysql/*
rm /var/log/apache2/*.gz
rm /var/log/apache2/*.1
rm /var/www/logs_otp/*.gz
rm /var/www/logs_otp/*.1
truncate -s 0 /var/log/*
truncate -s 0 /var/log/apache2/*.log
truncate -s 0 /var/www/logs_otp/*.log

#Nettoyer les sauvegardes
rm /var/www/backup/sql/otp/*.sql
rm /var/www/backup/conf/*.zip
rm -R /var/www/backup/global_backup/*
rm -R /var/www/tmp/*

#Nettoyer les caches
rm /var/backups/*
rm -R /var/cache/apt/*
rm /root/.ssh/known_hosts

#Nettoyer /home
rm -R -f /home/*

#Nettoyer Cache
rm /var/cache/debconf/config.dat-old
rm /var/cache/debconf/templates.dat-old
rm /var/lib/apt/lists/*
rm /var/lib/collectd/rrd/* -R

#Protection de /dbase
echo "Deny from all" >/var/www/html/dbase/.htaccess

#Remise en conf usine du /etc/passwd
sed -i '/root:x:0:0:root/c\root:x:0:0:root:/root:/usr/local/bin/wizard.sh' /etc/passwd

#Nettoyer l'historique
rm /root/.bash_history
rm /root/.nano/search_history
rm /root/.lesshst
rm /roo/.listusers.php.swp
rm /etc/freeradius/.bash_history
history -c


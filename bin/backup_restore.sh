#!/bin/bash
#Derniere modification le : 02/05/2022
#Par : Laurent ASSELIN

#unzip
unzip -q $1 -d /var/www/tmp
if [ $? -ne 0 ]; then
    echo "fail 5"
    exit 84
fi

rm $1
if [ $? -ne 0 ]; then
    echo "fail 6"
    exit 84
fi

#nettoyage du dossier home
sudo rm -rf /home/*

#restauration du dossier home
sudo cp -r /var/www/tmp/home/ /

if [ $? -ne 0 ]; then
    echo "fail 1"
    exit 84
fi

chown -R freerad:freerad /home/

#Pour check si la copie c'est bien passé insérer le code en dessous
#if [ $? -ne 0 ]; then
#echo "fail"
#exit 84
#fi

#restauration des autres dossiers
sudo rm -f /etc/pam.d/radiusd_*
sudo cp /var/www/tmp/radiusd/* /etc/pam.d/
chown freerad:freerad /etc/pam.d/radiusd_*
sudo rm -f /etc/freeradius/mods-available/pam_*
sudo cp /var/www/tmp/pam/available/* /etc/freeradius/mods-available/
sudo rm -f /etc/freeradius/mods-enabled/pam_*
sudo cp /var/www/tmp/pam/enabled/* /etc/freeradius/mods-enabled/
sudo rm -f /etc/freeradius/sites-available/*
sudo cp /var/www/tmp/d/available/* /etc/freeradius/sites-available/
sudo rm -f /etc/freeradius/sites-enabled/*
sudo cp /var/www/tmp/d/enabled/* /etc/freeradius/sites-enabled/
sudo cp /var/www/tmp/conf/clients.conf /etc/freeradius/clients.conf
chown -R freerad:freerad /etc/freeradius/
sudo rm -f /etc/pam_ldap_*
sudo cp /var/www/tmp/ldap/* /etc/
sudo cp /var/www/tmp/img/brandmark.png /var/www/html/assets/images/brandmark.png
sudo chown freerad:freerad /var/www/html/assets/images/brandmark.png
sudo service freeradius restart

#restauration de la base de donnée

dbfile=$(find /var/www/tmp/ -maxdepth 1 -type f -name *.sql)
if [ $? -ne 0 ]; then
    echo "fail 3"
    exit 84
fi

db_password=$(cat /etc/mysql/otp.conf | tr -d " \t\n\r")

mysql --user=admin_exer --password=$db_password < $dbfile
if [ $? -ne 0 ]; then
    echo "fail 4"
    exit 84
fi

#Restauration du mot de passe admin_exer
sudo cp /var/www/tmp/mysql/otp.conf /etc/mysql

#Restauration des certificats TLS pour la WebUI
sudo cp /var/www/tmp/exer_otp/* /opt/certs/exer_otp/

#supprimer tout le contenu de tmp/
rm -r /var/www/tmp/*
if [ $? -ne 0 ]; then
    echo "fail 7"
    exit 84
fi

echo "done"

#Redemarrage de MySQL, necessaire car le mdp du compte "app_exerotp" a changé !
sudo service mysql restart

#Redemarrage de Apache, necessaire car on vient de changer les certificats TLS
sudo service apache2 restart



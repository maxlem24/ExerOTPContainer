#!/bin/bash
#Derniere modification le : 02/05/2022
#Par : Laurent Asselin

#restauration des données de la vm

#suppression des données du dossier home (sans supprimer la licence)
find /home -maxdepth 1 -type f  ! -name "*.license" | xargs echo

#suppression des données dans la base exer_db
mysql -u admin_exer -p --database=exer_db -e "delete from otp_tokens;"
mysql -u admin_exer -p --database=exer_db -e "delete from otp_connections;"
mysql -u admin_exer -p --database=exer_db -e "delete from otp_companies;"
mysql -u admin_exer -p --database=exer_db -e "delete from otp_users where id <> 1;"
#mysql -u admin_exer -p --database=exer_db -e "delete from otp_firewall;"

#a rajouter plus tard remise a zero de la table otp_ldap

#suppression des fichers pam
find /etc/pam.d/ -maxdepth 1 -type f -name "radiusd_*" ! -name "radiusd_" ! -name "radiusd_skel" | xargs echo
find /etc/freeradius/mods-available/ -maxdepth 1 -type f -name "pam_*" ! -name "pam_" ! -name "pam_skel" | xargs echo
find /etc/freeradius/sites-available/ -maxdepth 1 -type f -name "*" ! -name "skel" | xargs echo
#dois-je faire un  sudo service freeradius restart après ?

sudo service freeradius restart

#suppressions des données des fichiers de logs
rm /var/www/logs_otp/actions_otp.log
touch /var/www/logs_otp/actions_otp.log

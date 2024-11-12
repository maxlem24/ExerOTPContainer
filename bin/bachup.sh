#!/bin/bash
#Derniere modification le : 02/05/2022
#Par : Laurent Asselin

#date du jour
backupdate=$(date +%Y-%m-%d)

#Verification que le dossier backup existe
if [ ! -d "/backup" ]; then
    mkdir /backup
fi

#répertoire de backup
dirbackup=/var/www/backup/global_backup/backup-$backupdate

#suppression du contenu du dossier backup
sudo rm -rf $dirbackup

#autres répertoires
dirpam_enabled=$dirbackup/pam/enabled
dirpam_available=$dirbackup/pam/available
dirradiusd=$dirbackup/radiusd
dird_enabled=$dirbackup/d/enabled
dird_available=$dirbackup/d/available
dirldap=$dirbackup/ldap
dirconf=$dirbackup/conf
dirsql=$dirbackup/mysql
dirhome=$dirbackup/home
dircerts=$dirbackup/exer_otp
dirimg=$dirbackup/img

#création du répertoir de backup
mkdir $dirbackup
chown freerad:freerad $dirbackup  
mkdir $dirbackup/pam
mkdir $dirbackup/d
mkdir $dirradiusd
mkdir $dirpam_enabled
mkdir $dirpam_available
mkdir $dird_enabled
mkdir $dird_available
mkdir $dirldap
mkdir $dirconf
mkdir $dirsql
mkdir $dirhome
mkdir $dircerts
mkdir $dirimg

#importation de /home
cp -r /home/* $dirhome
if [ $? -ne 0 ]; then
    echo "fail"
    exit 84
fi

#sauvegarde mysql

db_password=$(cat /etc/mysql/otp.conf | tr -d " \t\n\r")

sudo mysqldump --user=admin_exer --password=$db_password --opt --all-databases >  $dirbackup/db-$backupdate.sql
if [ $? -ne 0 ]; then
    echo "fail"
    exit 84
fi

cp /var/www/html/assets/images/brandmark.png $dirimg
sudo cp /opt/certs/exer_otp/* $dircerts
cp /etc/mysql/otp.conf $dirsql
cp /etc/pam.d/radiusd_* $dirradiusd
cp /etc/freeradius/mods-available/pam_* $dirpam_available
cp /etc/freeradius/sites-available/* $dird_available
cp /etc/freeradius/mods-enabled/pam_* $dirpam_enabled
cp /etc/freeradius/sites-enabled/* $dird_enabled
cp /etc/pam_lda* $dirldap
cp /etc/freeradius/clients.conf $dirconf

#compression de toutes les données
cd $dirbackup
all_file=$(find . -maxdepth 1 \( ! -name *.zip ! -name . \))
zip -rq backup-$backupdate.zip $all_file
if [ $? -ne 0 ]; then
    echo "fail"
    exit 84
fi

#suppression de tous les fichier sauf du fichier zip et du repertoir
find . -maxdepth 1 \( ! -name *.zip ! -name . \) | xargs rm -r
if [ $? -ne 0 ]; then
    echo "fail"
    exit 84
fi

#Changement des droits
chown freerad:freerad $dirbackup
chown freerad:freerad $dirbackup/*

echo "done"

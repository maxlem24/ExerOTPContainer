wait_mariadb(){
	until nc -z -w5 localhost 3306; do
		sleep 1
	done

	echo "MariaDB is ready!"

}

# Database config

/etc/init.d/mariadb restart

wait_mariadb

tr -dc A-Za-z0-9 < /dev/urandom | head -c 12 > /etc/mysql/otp.conf

RANDOMPASS=$(cat /etc/mysql/otp.conf)

sed -i "s/password/$RANDOMPASS/g" /root/init_db.sql

mariadb < /root/exer_db.sql
mariadb < /root/init_db.sql
sleep 1

# Remove root user
mariadb -u admin_exer -p$RANDOMPASS -e "DROP USER IF EXISTS 'root'@'localhost';"
php /usr/local/bin/app_exerotp.php

# Network

sed "2i127.0.1.1 EXER-TOTP.exer.fr EXER-TOTP" /etc/hosts > /tmp/temp && cat /tmp/temp > /etc/hosts
echo "domain exer.fr" >> /etc/resolv.conf
echo "search exer.fr" >> /etc/resolv.conf

# Freeradius

# Linking available <=> enabled
ln -s /etc/freeradius/mods-available/* /etc/freeradius/mods-enabled
ln -s /etc/freeradius/sites-available/* /etc/freeradius/sites-enabled

# Linking with 3.0
rm -r /etc/freeradius/3.0/*

ln -s /etc/freeradius/radiusd.conf /etc/freeradius/3.0/radiusd.conf
ln -s /etc/freeradius/clients.conf /etc/freeradius/3.0/clients.conf

ln -s /etc/freeradius/mods-enabled /etc/freeradius/3.0/mods-enabled
ln -s /etc/freeradius/mods-config /etc/freeradius/3.0/mods-config
ln -s /etc/freeradius/sites-enabled /etc/freeradius/3.0/sites-enabled
ln -s /etc/freeradius/policy.d /etc/freeradius/3.0/policy.d

# Remove init SQL files and make wizard.sh more accessible

rm /root/*.sql
ln -s /usr/local/bin/wizard.sh /root/wizard.sh

# Restart the services

/etc/init.d/apache2 restart
/etc/init.d/freeradius restart

/bin/bash

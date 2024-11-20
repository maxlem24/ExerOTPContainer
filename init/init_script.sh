RANDOMPASS=$(cat /etc/mysql/otp.conf)

wait_mariadb(){
	until nc -z -w5 localhost 3306; do
		sleep 1
	done

	echo "MariaDB is ready!"

}

# Database config

/etc/init.d/mariadb restart

wait_mariadb

sed -i "s/password/$RANDOMPASS/g" /root/init_db.sql

mariadb < /root/exer_db.sql
mariadb < /root/init_db.sql
sleep 1
mariadb -u admin_exer -p$RANDOMPASS -e "DROP USER IF EXISTS 'root'@'localhost';"

# Network

sed "2i127.0.1.1 EXER-TOTP.exer.fr EXER-TOTP" /etc/hosts > /tmp/temp && cat /tmp/temp > /etc/hosts
echo "domain exer.fr" >> /etc/resolv.conf
echo "search exer.fr" >> /etc/resolv.conf

bash /usr/local/bin/wizard.sh

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

/etc/init.d/apache2 restart
/etc/init.d/freeradius restart

/bin/bash

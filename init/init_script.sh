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

mariadb < /root/init_db.sql

# Network

sed "2i127.0.1.1 EXER-TOTP.exer.fr EXER-TOTP" /etc/hosts > /tmp/temp && cat /tmp/temp > /etc/hosts
echo "domain exer.fr" >> /etc/resolv.conf
echo "search exer.fr" >> /etc/resolv.conf

bash /usr/local/bin/wizard.sh

/etc/init/apache2 restart

/bin/bash

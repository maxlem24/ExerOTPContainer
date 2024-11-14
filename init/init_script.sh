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

sed -i -e "s/password/$RANDOMPASS/g" /root/init_db.sql

mariadb < /root/init_db.sql

# Network

sed "2i127.0.1.1 EXER-TOTP.exer.fr EXER-TOTP" /etc/hosts > /tmp/temp && cat /tmp/temp > /etc/hosts

bash /usr/local/bin/wizard.sh

/bin/bash

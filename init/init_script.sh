RANDOMPASS=$(cat /etc/mysql/otp.conf)

wait_mariadb(){
	until nc -z -w5 localhost 3306; do
		sleep 1
	done

	echo "MariaDB is ready!"

}

/etc/init.d/mariadb restart

wait_mariadb

mariadb < /root/init_db.sql

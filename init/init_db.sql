CREATE USER 'admin_exer'@'%' IDENTIFIED BY '${RANDOMPASS}';
CREATE USER 'app_exerotp'@'localhost' IDENTIFIED BY '${RANDOMPASS}';
DROP USER 'root'@'localhost';
DROP USER 'mysql'@'localhost';
DROP USER 'mariadb.sys'@'localhost';

GRANT ALL PRIVILEGES ON *.* TO 'admin_exer'@'%';

FLUSH PRIVILEGES;
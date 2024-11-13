CREATE USER 'admin_exer'@'%' IDENTIFIED WITH 'mysql_native_password' BY '${RANDOMPASS}';
CREATE USER 'app_exerotp'@'localhost' IDENTIFIED WITH 'mysql_native_password' BY '${RANDOMPASS}';

GRANT ALL PRIVILEGES ON *.* TO 'admin_exer'@'%';

FLUSH PRIVILEGES;
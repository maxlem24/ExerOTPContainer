CREATE USER IF NOT EXISTS 'admin_exer'@'%' IDENTIFIED BY 'password';
CREATE USER IF NOT EXISTS'app_exerotp'@'localhost' IDENTIFIED BY 'password';

GRANT ALL PRIVILEGES ON *.* TO 'admin_exer'@'%';

FLUSH PRIVILEGES;

DROP USER IF EXISTS 'mysql'@'localhost';

SYSTEM mariadb -u admin_exer -ppassword;

DROP USER IF EXISTS 'root'@'localhost';

EXIT
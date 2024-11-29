# EXER OTP Container

## Files contents :

- /bin : copy of /usr/local/bin 

**Warning :** *wizard.sh* has been modified to replace sed in the host files, and to remove the possibility to change the IP address	
- /certs : copy of /opt/certs
- /config : copy of usefuls config files in /etc/mysql/mariadb.conf.d/config
- /init : sh and sql scripts to init the database and configure services
- /lib : copy of /usr/local/lib + /usr/lib/libgraypam.so.0
- /pam : copy of /etc/pam.d/radius_skel and /etc/pam.d/radius_skel_mfa
- otp_sudoers : permission file for the user freerad
- freeradius.zip : copy of /etc/freeradius, with change in radiusd.conf : "raddbdir = /etc/freeradius" => "raddbdir = /etc/freeradius/3.0"
- www.zip : copy of /var/www

## Init scripts
- init_script.sh : Start MariaDB, run the following scripts, and solve network and freeradius issues
- init_db.sql : add services users "admin_exer" and "app_exerotp" in MariaDB, and remove useless users
- exer_db.sql : dump of the table "exer_db"

## Build the image and run the Container

- Open a terminal in the folder where the Dockerfile is located
- Run *docker build -t image_name .* to build the image
- Run *docker run -p 443:443 -p 1812:1812/udp -dt --name container_name image_name* to launch the container
- Run *docker exec -it container_name bash* to open a terminal inside the container


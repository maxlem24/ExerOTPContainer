#!/bin/bash
#Derniere modification le : 21/07/2023
#Par : Laurent ASSELIN

# network vars
NETWORK_FILE="/etc/network/interfaces"
MAIL_FILE="/etc/postfix/main.cf"
NTP_FILE="/etc/systemd/timesyncd.conf"
DEFAULTNTP=`egrep -i '^(|#)ntp' /etc/systemd/timesyncd.conf | cut -d "=" -f2`
DEFAULTML=`grep relayhost "${MAIL_FILE}" | cut -f 3 -d " " `
DEFAULTIF=`grep allow-hotplug /etc/network/interfaces | cut -f 2 -d " "`
DEFAULTIP=`grep address /etc/network/interfaces | cut -f 2 -d " "`
DEFAULTMK=`grep netmask /etc/network/interfaces | cut -f 2 -d " "`
DEFAULTGW=`grep gateway /etc/network/interfaces | cut -f 2 -d " "`
INTERFACE=`ls /sys/class/net -m | cut -f 1 -d ","`

# hosts vars
HOSTS_FILE="/etc/hosts"
DNS_FILE="/etc/resolv.conf"
DEFAULTHOSTNAME=`grep 127.0.1.1 /etc/hosts | awk '{print $3}'`
DEFAULTFQDN=`grep 127.0.1.1 /etc/hosts | awk '{print $2}'`
DEFAULTDOMAIN=`grep search /etc/resolv.conf | cut -f 2 -d " "`
DEFAULTNS=`grep nameserver /etc/resolv.conf | cut -f 2 -d " "`

# to ease reading of script output
WAIT_SEC="1"


valid_ip(){
        VALID=`echo $1 | grep -P "^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$"`
        if [ -z "${VALID}" ]; then
                return 1
        else
                return 0
        fi
}


valid_fqdn(){
        RESULT=`echo ${1} | grep -P '(?=^.{4,253}$)(^((?!-)[a-zA-Z0-9-]{1,63}(?<!-)\.)+[a-zA-Z]{2,63}$)'`
        if [ -z "${RESULT}" ]; then
                return 1
        else
                return 0
        fi
}


conf_gateway(){

	read -p "[➖] Default gateway: [${DEFAULTGW}] " GATEWAY
    if [ -z "${GATEWAY}" ]; then
		GATEWAY="${DEFAULTGW}"
	fi
	valid_ip "${GATEWAY}"
	if [ $? -ne 0 ]; then
		echo "[⚠] Error: The address is invalid."
		return 1
	fi

	sed -i -e 's/'"gateway ${DEFAULTGW}"'/'"gateway ${GATEWAY}"'/g' ${NETWORK_FILE}
	if [ $? -ne 0 ]; then
		echo "[⚠] Error: Unable to set default gateway."
		return 1
	fi

	return 0
}

conf_mail(){

        read -p "[➖] Default SMTP Server : [${DEFAULTML}] " IPFQDNMAIL
        if [ -z ${IPFQDNMAIL} ]; then
            IPFQDNMAIL="${DEFAULTML}"
        fi
        valid_ip "${IPFQDNMAIL}"
        TESTIPMAIL=$?
        valid_fqdn "${IPFQDNMAIL}"
        TESTFQDNMAIL=$?
        if [ ${TESTIPMAIL} -eq 0 ] || [ ${TESTFQDNMAIL} -eq 0 ]; then
                sed -i -e 's/'"relayhost = ${DEFAULTML}"'/'"relayhost = ${IPFQDNMAIL}"'/g' ${MAIL_FILE}
					if [ $? -ne 0 ]; then
						echo "[⚠] Error: Unable to change default SMTP server."
						return 1
					fi
                service postfix restart
        else
                        echo "[⚠] Error: invalid IP address or FQDN"
                        return 1
        fi

        return 0
}

ask_dns_settings(){
	ERR_DNS_CONFIG=1
	# On supprime les sauts de lignes si plusieurs serveurs
	DEFAULTNS=`echo $DEFAULTNS`
	while [ ${ERR_DNS_CONFIG} -ne 0 ]; do
		read -p "[➖] DNS Server(s) (space-separated) : [${DEFAULTNS}] " NAMESERVER
		if [ -z "${NAMESERVER}" ]; then
			NAMESERVER="${DEFAULTNS}"
		fi
		myarray=($NAMESERVER)
		ALLIP=1
		for (( i=0; i<${#myarray[@]}; i++ )); do
		
			valid_ip ${myarray[$i]}
			TESTIPNTP=$?
			
			if [ $(( ${TESTIPNTP} )) != 0 ]; then
				echo "[⚠] Error: "${myarray[$i]}" is not a valid IP address"
				ALLIP=0
				break
			fi
		done
		if [ $(( ${ALLIP} )) = 1 ]; then
			# Toutes les IP sont valides donc on peut écrire la configuration
			ERR_DNS_CONFIG=0
			sed -i '/^nameserver/d' ${DNS_FILE}
			for (( i=0; i<${#myarray[@]}; i++ )); do
				echo "nameserver ${myarray[$i]}" >> ${DNS_FILE}
			done	
			if [ $? -ne 0 ]; then
				echo "[⚠] Error: Unable to set NTP Servers."
				return 1
			fi
		fi
	done
	return 0
}


conf_ntp(){

	read -p "[➖] NTP Server(s) (space-separated) : [${DEFAULTNTP}] " IPFQDNNTP
	if [ -z "${IPFQDNNTP}" ]; then
		IPFQDNNTP="${DEFAULTNTP}"
	fi
	myarray=($IPFQDNNTP)
	for (( i=0; i<${#myarray[@]}; i++ )); do
		
		valid_ip ${myarray[$i]}
		TESTIPNTP=$?
		valid_fqdn ${myarray[$i]}
		TESTFQDNNTP=$?
		if [ $(( ${TESTIPNTP} ^ ${TESTFQDNNTP} )) != 1 ]; then
			echo "[⚠] Error: "${myarray[$i]}" is not a valid IP address or FQDN"
			return 1
		fi
	done
	sed -i "s/^#NTP=.*/NTP=$IPFQDNNTP/g;s/^NTP=.*/NTP=$IPFQDNNTP/g" "$NTP_FILE";
		if [ $? -ne 0 ]; then
			echo "[⚠] Error: Unable to set NTP Servers."
			return 1
		fi
	systemctl restart systemd-timesyncd.service		
		if [ $? -ne 0 ]; then
			echo "[⚠] Error: Unable to restart systemd-timesyncd service."
			return 1
		fi
	return 0
}

ask_if_config(){

	read -p "[➖] IP Address : [${DEFAULTIP}] " ADDRESS
	if [ -z "${ADDRESS}" ]; then
		ADDRESS="${DEFAULTIP}"
	fi
	# Static IP
	valid_ip "${ADDRESS}"
	if [ $? -ne 0 ]; then
		echo "[⚠] Error: The address entered is invalid."
		return 1
	fi

	read -p "[➖] Subnet mask : [${DEFAULTMK}] " MASK
	if [ -z "${MASK}" ]; then
		MASK="${DEFAULTMK}"
	fi
	valid_ip "${MASK}"
	if [ $? -ne 0 ]; then
		echo "[⚠]Error: The address entered is invalid."
		return 1
	fi

	sed -i -e 's/'"${DEFAULTIF}"'/'"${INTERFACE}"'/g' ${NETWORK_FILE}
	sed -i -e 's/'"address ${DEFAULTIP}"'/'"address ${ADDRESS}"'/g' ${NETWORK_FILE}
	sed -i -e 's/'"netmask ${DEFAULTMK}"'/'"netmask ${MASK}"'/g' ${NETWORK_FILE}
	
	if [ $? -ne 0 ]; then
		echo "[⚠] Error: Unable to configure network."
		return 1
	fi

	return 0
}


ask_network_settings(){
		ERR_NET_CONFIG=1
		ERR_MAIL_CONFIG=1
		while [ ${ERR_NET_CONFIG} -ne 0 ]; do
			ask_if_config
			ERR_NET_CONFIG=$?

			if [ ${ERR_NET_CONFIG} -eq 0 ]; then
					# Static: Ask for a static gateway IP address
					conf_gateway
					ERR_NET_CONFIG=$?
			fi
			[ ${ERR_NET_CONFIG} -ne 0 ] && echo "[⚠] Error: incorrect network settings."
		done

		while [ ${ERR_MAIL_CONFIG} -ne 0 ]; do
			conf_mail
			ERR_MAIL_CONFIG=$?
		done
		

	ADDRESS0=${ADDRESS}
}

ask_time_settings(){
		ERR_NTP_CONFIG=1
		read -p "[➖] Do you want to change NTP server (y/N)? " REQUEST
		if [ "${REQUEST}" = "y" ]; then
			while [ ${ERR_NTP_CONFIG} -ne 0 ]; do
				conf_ntp
				ERR_NTP_CONFIG=$?
			done

		fi
		echo " "
		CURRENT_TZ=$(cat /etc/timezone)
		echo "Current Time Zone is : $CURRENT_TZ"
		read -p "[➖] Do you want to change it (y/N)? " REQUEST
			if [ "${REQUEST}" = "y" ]; then
			dpkg-reconfigure tzdata
		fi
		
}

ask_host_settings(){

	read -p "[➖] Hostname (without suffix): [${DEFAULTHOSTNAME}] " HOSTNAME
	if [ -z "${HOSTNAME}" ]; then
		HOSTNAME="${DEFAULTHOSTNAME}"
	fi
	
	read -p "[➖]  DNS Suffix : [${DEFAULTDOMAIN}] " SUFFIX
	if [ -z "${SUFFIX}" -o "${SUFFIX}" = "${SUFFIX}\n" ]; then
		SUFFIX="${DEFAULTDOMAIN}"
	fi

	bash -c "echo ${SUFFIX}>/etc/mailname"
	bash -c "echo ${HOSTNAME}>/etc/hostname"

	sed -i -e "s/$DEFAULTHOSTNAME/$HOSTNAME/g"  ${MAIL_FILE}
	sed -i -e "s/$DEFAULTDOMAIN/$SUFFIX/g"  ${MAIL_FILE}
	
	FQDN="${HOSTNAME}.${SUFFIX}"
	sed -i -e 's/'"${DEFAULTFQDN}"'/'"${FQDN}"'/g' ${HOSTS_FILE}
	sed -i -e 's/'"${DEFAULTHOSTNAME}"'/'"${HOSTNAME}"'/g' ${HOSTS_FILE} 
	
	sed -i -e 's/'"${DEFAULTDOMAIN}"'/'"${SUFFIX}"'/g' ${DNS_FILE} 
	
	if [ $? -ne 0 ]; then
		echo "[⚠] Error: Unable to configure hostname."
		return 1
	fi
	
	return 0
}

regenerate_ssl_cert() {
	echo ""
	echo "[➖] Issuing a new TLS certificate for the WebUI..."
	echo ""
CONFIG="
[req]
distinguished_name=dn
[ dn ]
[ ext ]
basicConstraints=CA:FALSE,pathlen:0
"
	cp /opt/certs/exer_otp/server.key /opt/certs/exer_otp/server.key.bak
	cp /opt/certs/exer_otp/server.crt /opt/certs/exer_otp/server.crt.bak
	openssl req -config <(echo "$CONFIG") -subj "/CN="${FQDN}"/O=Exer/C=FR" -new -newkey rsa:2048 -sha256 -days 390 -nodes -x509 -keyout /opt/certs/exer_otp/server.key -out /opt/certs/exer_otp/server.crt
}

regenerate_ssh_keys() {
	VERIFY_AM_I_PUBLISHER=`grep "/bin/bash /usr/local/bin/publisher.sh -H" /etc/crontab`;
	VERIFY_AM_I_SUBSCRIBER=`grep "-e ssh -azu /home/ freerad@" /etc/crontab`;
	if [ ! -z "${VERIFY_AM_I_SUBSCRIBER}" ] || [ ! -z "${VERIFY_AM_I_PUBLISHER}" ]; then
		echo "Cluster Configuration Detected !!!"
		echo "Exiting before generating new SSH Keys (it would break the cluster)".
		exit 1;
	fi
	echo ""
	echo "[➖] Generating new OpenSSH keys..."
	echo ""
	sleep ${WAIT_SEC}
	rm /etc/ssh/ssh_host_*
	dpkg-reconfigure openssh-server
}

change_password() {
	echo ""
	echo "[〽] Please choose a new password for the 'root' account (for the console):"
	passwd root
	}

change_admin_mysql_password() {
    OLDMDP=$(cat /etc/mysql/otp.conf | tr -d " \t\n\r")
    
    M="0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    while [ "${n:=1}" -le "12" ]
    do pass="$pass${M:$(($RANDOM%${#M})):1}"
       let n+=1
    done

    mysqladmin -u admin_exer -p$OLDMDP password $pass
    if [ $? -ne 0 ]; then
	echo "An issue occurs while changing SQL admin password"
    else
		echo $pass > /etc/mysql/otp.conf
		php /usr/local/bin/app_exerotp.php
		service mysql restart
    fi

    echo ""
	echo "[➖] SQL admin password regeneration"
	echo ""
}

delete_call_to_wizard() {
    sed -i -e 's,'/usr/local/bin/wizard.sh','/bin/bash',g' /etc/passwd
}

ask_for_keyboard_language() {
echo "Please select your keyboard layout :"
echo "BE for Belgian (AZERTY)"
echo "CH for Swiss (QWERTZ)"
echo "FR for French (AZERTY)"
echo "NL for Dutch (QWERTY)"
echo "PL for Polish (QWERTY)"
echo "UK for British (QWERTY)"
echo "US for American (QWERTY)"
read -p "(FR/US/UK/BE/NL/CH/PL) [FR] : " language
	if [ -z "${language}" ]; then
		language="FR"
	fi
while [[  "$language" != "FR" && "$language" != "US" && "$language" != "UK" && "$language" != "BE" && "$language" != "NL" && "$language" != "CH" && "$language" != "PL" ]]
do
	read -p "(FR/US/UK/BE/NL/CH/PL) : " language
done

case $language in
"FR")
	sed -i -e '/XKBLAYOUT=/ s/=.*/="fr"/' /etc/default/keyboard
	setupcon
;;
"US")
	sed -i -e '/XKBLAYOUT=/ s/=.*/="us"/' /etc/default/keyboard
	setupcon
	## SQL injection of English e-mail templates "
	php /usr/local/bin/AddSQLTemplates.php
;;
"UK")
	sed -i -e '/XKBLAYOUT=/ s/=.*/="gb"/' /etc/default/keyboard
	setupcon
	## SQL injection of English e-mail templates "
	php /usr/local/bin/AddSQLTemplates.php
;;
"BE")
	sed -i -e '/XKBLAYOUT=/ s/=.*/="be"/' /etc/default/keyboard
	setupcon
	## SQL injection of English e-mail templates "
	php /usr/local/bin/AddSQLTemplates.php
;;
"NL")
	sed -i -e '/XKBLAYOUT=/ s/=.*/="nl"/' /etc/default/keyboard
	setupcon
	## SQL injection of English e-mail templates "
	php /usr/local/bin/AddSQLTemplates.php
;;
"CH")
	sed -i -e '/XKBLAYOUT=/ s/=.*/="ch"/' /etc/default/keyboard
	setupcon
	## SQL injection of English e-mail templates "
	php /usr/local/bin/AddSQLTemplates.php
;;
"PL")
	sed -i -e '/XKBLAYOUT=/ s/=.*/="pl"/' /etc/default/keyboard
	setupcon
	## SQL injection of English e-mail templates "
	php /usr/local/bin/AddSQLTemplates.php
;;
esac
}

# Main Wizard
USAGE="Usage: $0 [-d] [-h] [-k] [-n] [-t]\n\t -d : Change DNS Servers\n\t -h : Change Hostname\n\t -k : Change Keyboard\n\t -n : Change Network settings\n\t -t : Change Time Settings"

while getopts dhknt OPT; do
    case "$OPT" in
      d)
        echo " "
		ask_dns_settings
		echo " "
		exit 0 ;;
	  h)
        echo " "
		ask_host_settings
		echo " "
		exit 0 ;;
      k)
		echo " "
		ask_for_keyboard_language
		echo " "
		exit 0 ;;
	  n)
	  	echo " "
		ask_network_settings
		while [ $? -ne 0 ]; do
			sleep ${WAIT_SEC}
			ask_network_settings
		done
		echo " "
		echo "Please reboot in order new IP Settings to be taken into account"
		echo " "
		exit 0;;
	  t)
        echo " "
		ask_time_settings
		echo " "
		echo "Wait 10s then type the following command to check NTP logs"
		echo "journalctl --unit=systemd-timesyncd.service | tail -n4"
		echo " "
		exit 0 ;;
      [?])
        # got invalid option
        echo " "
		echo -e $USAGE >&2
		echo " "
        exit 1 ;;
    esac
done


echo ""
echo "	+--------------------------------------+"
echo "	|             Initial setup            |"
echo "	+--------------------------------------+"
echo "[⚠] You can quit at anytime using CTRL+C"
echo "[⚠] Use wizard.sh without option to start over"
echo ""

delete_call_to_wizard

# ask_for_keyboard_language

# ask_network_settings
# while [ $? -ne 0 ]; do
	# sleep ${WAIT_SEC}
	# ask_network_settings
# done

ask_time_settings

ask_host_settings

ask_dns_settings

change_password

change_admin_mysql_password

regenerate_ssh_keys

sleep ${WAIT_SEC}

regenerate_ssl_cert

echo ""
echo "+------------------------------------------+"
echo "|       [✔️] Initial setup completed        |"
echo "+------------------------------------------+"
echo "[➖] The server is restarting... Please wait..."
echo ""

sleep 3
reboot



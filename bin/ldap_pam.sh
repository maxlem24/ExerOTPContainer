#!/bin/bash
#Derniere modification le : 30/12/2020
#Par : Laurent ASSELIN

#Configuration de l'interco LDAP pour le MFA

USAGE="Usage : $0 -b basedn -u uri [-v uri2] -s (on|off) -d binddn -p password [-c client] [-l loginattribute]\n\rExemple : $0 -b dc=mycompany,dc=com -u 10.0.0.250 -v 10.0.0.251 -s on -d cn=read_only_account,dc=mycompany,dc=com -p password"
RADIUSLDAP="forward_pass\nauth required \/lib\/x86_64-linux-gnu\/security\/pam_ldap.so\nconfig=\/etc\/pam_ldap_$CLIENT$.conf use_first_pass"
CLIENT="default"
PAMLOGIN="samaccountname"

while getopts :c:b:u:v:s:d:p:l: OPT; do
	case "$OPT" in
		c)
		  CLIENT="$OPTARG" ;;
		b)
		  BASE="$OPTARG" ;;
		u)
		  URI="$OPTARG" ;;
		v)
		  URI2="$OPTARG" ;;
		s)
          SSL="$OPTARG" ;;
		l)
		  PAMLOGIN="$OPTARG" ;;
		d)
          BINDDN="$OPTARG" ;;
		p)
		  BINDPW="$OPTARG" ;;
		[?])
		echo -e $USAGE >&2
		exit 1 ;;
	esac
done

#Mise en minuscule du client et du login
CLIENT=$(echo "$CLIENT" | awk '{print tolower($0)}')

if [ "$CLIENT" = "skel" ]; then
    echo -e "Nom de client réservé, merci d'en choisir un autre" >&2
    exit 1
fi

if [ "$CLIENT" = "" ]; then
	echo -e $USAGE >&2
	exit 1

elif [ "$BASE" = "" ]; then
	echo -e $USAGE >&2
	exit 1

elif [ "$URI" = "" ]; then
	echo -e $USAGE >&2
	exit 1

elif [ "$SSL" = "" ]; then
    echo -e $USAGE >&2
    exit 1

elif [ "$BINDDN" = "" ]; then
	echo -e $USAGE >&2
	exit 1

elif [ "$BINDPW" = "" ]; then
	echo -e $USAGE >&2
	exit 1
fi

#Création du fichier pam_ldap spécifique au client
echo "base $BASE" > "/etc/pam_ldap_$CLIENT.conf"

if [ "$URI2" = "" ]; then
	echo "host $URI" >> "/etc/pam_ldap_$CLIENT.conf"
else
	echo "host $URI $URI2" >> "/etc/pam_ldap_$CLIENT.conf"
fi

echo "binddn $BINDDN" >> "/etc/pam_ldap_$CLIENT.conf"
echo "bindpw $BINDPW" >> "/etc/pam_ldap_$CLIENT.conf"
echo "bind_timelimit 3" >> "/etc/pam_ldap_$CLIENT.conf"
echo "ldap_version 3" >> "/etc/pam_ldap_$CLIENT.conf"
echo "pam_login_attribute $PAMLOGIN" >> "/etc/pam_ldap_$CLIENT.conf"
echo "pam_password ad" >> "/etc/pam_ldap_$CLIENT.conf"
echo "referrals no" >> "/etc/pam_ldap_$CLIENT.conf"

if [ "$SSL" = "on" ]; then
	echo "port 636" >> "/etc/pam_ldap_$CLIENT.conf"
	echo "ssl on" >> "/etc/pam_ldap_$CLIENT.conf"
	echo "tls_checkpeer no" >> "/etc/pam_ldap_$CLIENT.conf"
fi

#Création de la configuration PAM mode OTP Seul
if [ ! -f /etc/pam.d/radiusd_"$CLIENT" ]; then
    cat /etc/pam.d/radiusd_skel | sed "s/skel/$CLIENT/" > /etc/pam.d/radiusd_"$CLIENT"
    chown freerad:freerad /etc/pam.d/radiusd_"$CLIENT"
fi

#Création de la configuration PAM mode OTP + LDAP
if [ ! -f /etc/pam.d/radiusd_"${CLIENT}"_mfa ]; then
    cat /etc/pam.d/radiusd_skel_mfa | sed "s/skel/$CLIENT/" > /etc/pam.d/radiusd_"${CLIENT}"_mfa
    chown freerad:freerad /etc/pam.d/radiusd_"${CLIENT}"_mfa
fi

# fin du script ldap_pam.sh

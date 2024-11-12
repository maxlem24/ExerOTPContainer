#!/bin/bash
#Derniere modification le : 02/05/2022
#Par : Laurent ASSELIN

#Suppression d'un dossier client et les fichiers associés

USAGE="Usage: $0 -c client [-f] \n\t -c client : nom du client à supprimer\n\t -f : force la suppression (détruit tous les utilisateurs existants de ce client)"
CLIENT=""
FORCE="no"
while getopts c:f OPT; do
    case "$OPT" in
      c)
        CLIENT="$OPTARG" ;;
      f)
        FORCE="yes" ;;
      [?])
        # got invalid option
        echo -e $USAGE >&2
        exit 1 ;;
    esac
done

#Mise en minuscule du client et du login
CLIENT=$(echo "$CLIENT" | awk '{print tolower($0)}')
LOGIN=$(echo "$LOGIN" | awk '{print tolower($0)}')

if [ "$CLIENT" = "" ] || [ "$CLIENT" = "skel" ] || [ "$CLIENT" = "default" ]; then
	echo -e $USAGE >&2	
	exit 1
fi

if [ "$FORCE" = "yes" ]; then
	echo "Suppression des utilisateurs de $CLIENT"
	rm -R /home/"$CLIENT"
	echo "Suppression de la configuration de $CLIENT"
	rm /etc/pam.d/radiusd_"$CLIENT"
	rm /etc/freeradius/mods-available/pam_"$CLIENT"
	rm /etc/freeradius/mods-enabled/pam_"$CLIENT"
	rm /etc/freeradius/sites-available/"$CLIENT"
	rm /etc/freeradius/sites-enabled/"$CLIENT"
	
	rm /etc/pam.d/radiusd_${CLIENT}_mfa
	rm /etc/freeradius/mods-available/pam_${CLIENT}_mfa
	rm /etc/freeradius/mods-enabled/pam_${CLIENT}_mfa
	rm /etc/freeradius/sites-available/${CLIENT}_mfa
	rm /etc/freeradius/sites-enabled/${CLIENT}_mfa
	
	rm /etc/pam_ldap_"$CLIENT".conf
	
	service freeradius restart
	exit 0
fi

if [ ! -d "/home/$CLIENT" ]; then
	echo "Le dossier /home/$CLIENT n'existe pas, utiliser l'option -f pour forcer la suppression de la configuration".
	exit 1
fi

if [ "$(ls -A /home/$CLIENT)" ]; then
	echo "Le dossier /home/$CLIENT n'est pas vide, il reste peut-être encore des utilisateurs chez ce client"
	echo "Utiliser l'option -f pour forcer la suppression"
	exit 1
else
echo "Suppression de la configuration de $CLIENT"
	rm /etc/pam.d/radiusd_"$CLIENT"
	rm /etc/freeradius/mods-available/pam_"$CLIENT"
	rm /etc/freeradius/mods-enabled/pam_"$CLIENT"
	rm /etc/freeradius/sites-available/"$CLIENT"
	rm /etc/freeradius/sites-enabled/"$CLIENT"
	service freeradius restart
	exit 0
fi
#Fin du script rm_client.sh

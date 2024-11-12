#!/bin/bash
#Derniere modification le : 02/05/2022
#Par : Laurent ASSELIN

USAGE="Usage: $0 -f firewall"
FIREWALL=""
LIGNE1=""
IFS=

while getopts f: OPT; do
	case "$OPT" in
		f)
		  FIREWALL="$OPTARG" ;;
		[?])
		#invalid argument
		  echo "$USAGE"
		  exit 1 ;;
	esac
done

if [ "$FIREWALL" = "" ]
then
	echo "$USAGE"
	exit 1
fi

#verification si le client existe, prendre le numéro des lignes
if grep --quiet -w "$FIREWALL" /etc/freeradius/clients.conf; then
	LIGNE1=$(sed -n "/#startclient_$FIREWALL$/=" /etc/freeradius/clients.conf)
	LIGNE2=$(sed -n "/#endclient_$FIREWALL$/=" /etc/freeradius/clients.conf)
	sed -i """$LIGNE1","$LIGNE2"d"" /etc/freeradius/clients.conf

	exit 1
else
	echo "Le Firewall $FIREWALL n'a pas été trouvé. Veuillez vérifier la syntaxe."
fi

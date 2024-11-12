#!/bin/bash
#Derniere modification le : 02/05/2022
#Par : Laurent ASSELIN

#Declaration du NAS -client- RADIUS (IP Publique du firewall en général) dans le fichier clients.conf avec 2FA


is_fqdn() {
  hostname=$1
  [[ $hostname == *"."* ]] || return 1
  host -N 0 $hostname > /dev/null 2>&1 || return 1
}

USAGE="1"
CLIENT="default"
IP=""
SECRET=""
SHORTNAME=""
rx='([1-9]?[0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])'
WEB=""
while getopts i:c:s:n: OPT; do
    case "$OPT" in
      i)
        IP="$OPTARG" ;;
      c)
        CLIENT="$OPTARG" ;;
      s)
        SECRET="$OPTARG" ;;
      n)
        SHORTNAME="$OPTARG" ;;
      [?])
        # got invalid option
        echo -e $USAGE
        exit 1 ;;
    esac
done

#Mise en minuscule du client
CLIENT=$(echo "$CLIENT" | awk '{print tolower($0)}')

#Verification des paramètres
if [ "$IP" = "" ] ; then
	echo -e $USAGE	
	exit 1
fi

if [[ $IP =~ ^$rx\.$rx\.$rx\.$rx$ ]]; then
  echo "" >/dev/null
elif is_fqdn $IP; then
 echo "" >/dev/null
else 
 echo "2"
 exit 1
fi

#Verification qu'une entrée n'est pas déjà présente dans le fichier clients.conf
if grep --quiet $IP$ /etc/freeradius/clients.conf; then 
	echo "3"
	exit 1
fi

#Verification que nous disposons d'un "Short Name" qui n'est pas déjà présent
if [ "$SHORTNAME" = "" ]; then
	SHORTNAME="$CLIENT"
fi

if grep --quiet -w "client $SHORTNAME" /etc/freeradius/clients.conf; then 
	echo "4"
	exit 1
fi

#Si aucun secret fournit, en générer un et l'afficher
if [ "$SECRET" = "" ]; then
	SECRET=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 20)
fi

#Inscription dans le fichier clients.conf

#echo " " >> /etc/freeradius/clients.conf
echo '#'"startclient_$SHORTNAME" >> /etc/freeradius/clients.conf
echo "client $SHORTNAME {" >> /etc/freeradius/clients.conf
echo "        ipaddr          = $IP" >> /etc/freeradius/clients.conf
echo "        secret          = $SECRET" >> /etc/freeradius/clients.conf
echo "        virtual_server  = ${CLIENT}_mfa" >> /etc/freeradius/clients.conf
echo "}" >> /etc/freeradius/clients.conf
echo '#'"endclient_$SHORTNAME" >> /etc/freeradius/clients.conf

#Affiche le résultat et redémarre le serveur
echo "0"
sudo service freeradius restart
#Fin du script nas_client_apache_mfa.sh

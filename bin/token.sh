#!/bin/bash
#Derniere modification le : 02/05/2022
#Par : Laurent ASSELIN

#Création de l'utilisateur TOTP

DEFAULTISSUER="Exer"
USAGE="Usage: $0 -l login [-c client] [-i issuer] [-n nom] [-d expiration]\n\t -l login : nom d'utilisateur (obligatoire)\n\t -c client : nom du client (recommandé pour éviter les collisions)\n\t -i issuer : fournisseur (apparait sur certaines appli, égal au client sinon $DEFAULTISSUER)\n\t -n name : nom du token (apparait sur certaines appli, par defaut : le login)\n\t -d expiration (à titre informatif uniquement)"
LOGIN=""
CLIENT="default"
ISSUER=""
NAME=""
DATEEXPI=""
RELOAD="no"

while getopts l:c:i:n:d: OPT; do
    case "$OPT" in
      l)
        LOGIN="$OPTARG" ;;
      c)
        CLIENT="$OPTARG" ;;
      i)
        ISSUER="$OPTARG" ;;
      n)
	NAME="$OPTARG" ;;
      d)
        DATEEXPI="$OPTARG" ;;
      [?])
        # got invalid option
        echo -e $USAGE >&2
        exit 1 ;;
    esac
done
if [ "$LOGIN" = "" ]; then
	echo -e $USAGE >&2	
	exit 1
fi

if [ "$NAME" = "" ] && [  "$ISSUER" = "" ]; then
       NOFILE="yes"
fi

if [ "$ISSUER" = "" ]; then
	ISSUER="$DEFAULTISSUER"
fi

if [ "$NAME" = "" ]; then
       NAME="$LOGIN" 
fi

if [ "$CLIENT" = "skel" ]; then
	echo -e "Nom de client réservé, merci d'en choisir un autre" >&2	
	exit 1
fi

if [ "$CLIENT" != "default" ] && [ "$ISSUER" == "$DEFAULTISSUER" ]; then
    ISSUER="$CLIENT"
fi

if [ "$CLIENT" == ""  ]; then
    CLIENT="default"
fi

#Déplacement vers un répertoire temporaire
export HOME="/home"
cd /home

#Création du token Exer-Authenticator
echo "-1" | /usr/local/bin/exer-authenticator -f -t -D -S 30 -r 3 -R 30 -Q utf8 -w 3 -i "$ISSUER" -C "$CLIENT" -l "$NAME"

if [ $? -ne 84 ]; then

    
    #Mise en minuscule du client et du login
    CLIENT=$(echo "$CLIENT" | awk '{print tolower($0)}')
    LOGIN=$(echo "$LOGIN" | awk '{print tolower($0)}')

    
    #Déplacement du secret de l utilisateur dans son dossier final ainsi que la date d expiration
    mkdir -p /home/"$CLIENT"/"$LOGIN"
    mv /home/.exer_authenticator /home/"$CLIENT"/"$LOGIN"
    
    chown freerad:freerad /home/"$CLIENT"
    chown freerad:freerad /home/"$CLIENT"/"$LOGIN"
    chown freerad:freerad /home/"$CLIENT"/"$LOGIN"/.exer_authenticator
    
    #Sauvegarde des infos pour regénérer le QRCode plus tard
    echo "issuer $ISSUER" > /home/"$CLIENT"/"$LOGIN"/.nameandissuer
    echo "nametoken $NAME" >> /home/"$CLIENT"/"$LOGIN"/.nameandissuer
    chown freerad:freerad /home/"$CLIENT"/"$LOGIN"/.nameandissuer
    
    echo "date $DATEEXPI" > /home/"$CLIENT"/.dateexpi_"$CLIENT"
    chown freerad:freerad /home/"$CLIENT"/.dateexpi_"$CLIENT"
    
    #Création d'un nouveau client si nécessaire
    if [ "$CLIENT" != "default" ]; then
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
	
	#Création du module PAM du serveur Freeradius mode OTP Seul
	if [ ! -f /etc/freeradius/mods-available/pam_"$CLIENT" ]; then
        cat /etc/freeradius/mods-available/pam_skel | sed "s/skel/$CLIENT/" > /etc/freeradius/mods-available/pam_"$CLIENT"
		ln -s /etc/freeradius/mods-available/pam_"$CLIENT" /etc/freeradius/mods-enabled/pam_"$CLIENT"
	    chown freerad:freerad /etc/freeradius/mods-available/pam_"$CLIENT"
		chown freerad:freerad /etc/freeradius/mods-enabled/pam_"$CLIENT" -h
				RELOAD="yes"
	fi
	
	#Création du module PAM du serveur Freeradius mode OTP + LDAP
	if [ ! -f /etc/freeradius/mods-available/pam_"${CLIENT}"_mfa ]; then
        cat /etc/freeradius/mods-available/pam_skel | sed "s/skel/${CLIENT}_mfa/" > /etc/freeradius/mods-available/pam_"${CLIENT}"_mfa
		ln -s /etc/freeradius/mods-available/pam_"${CLIENT}"_mfa /etc/freeradius/mods-enabled/pam_"${CLIENT}"_mfa
		chown freerad:freerad /etc/freeradius/mods-available/pam_"${CLIENT}"_mfa
		chown freerad:freerad /etc/freeradius/mods-enabled/pam_"${CLIENT}"_mfa -h
		RELOAD="yes"
	fi 
	
	#Création du serveur virtuel Freeradius mode OTP Seul
	if [ ! -f /etc/freeradius/sites-available/"$CLIENT" ]; then
	    cat /etc/freeradius/sites-available/skel | sed "s/skel/$CLIENT/" > /etc/freeradius/sites-available/"$CLIENT"
	    ln -s /etc/freeradius/sites-available/"$CLIENT" /etc/freeradius/sites-enabled/"$CLIENT"
	    chown freerad:freerad /etc/freeradius/sites-available/"$CLIENT"
       	chown freerad:freerad /etc/freeradius/sites-enabled/"$CLIENT" -h
		RELOAD="yes"
	fi
	
		#Création du serveur virtuel Freeradius mode OTP + LDAP
	if [ ! -f /etc/freeradius/sites-available/"${CLIENT}"_mfa ]; then
	    cat /etc/freeradius/sites-available/skel | sed "s/skel/${CLIENT}_mfa/" > /etc/freeradius/sites-available/"${CLIENT}"_mfa
	    ln -s /etc/freeradius/sites-available/"${CLIENT}"_mfa /etc/freeradius/sites-enabled/"${CLIENT}"_mfa
	    chown freerad:freerad /etc/freeradius/sites-available/"${CLIENT}"_mfa
       	chown freerad:freerad /etc/freeradius/sites-enabled/"${CLIENT}"_mfa -h
		RELOAD="yes"
	fi
	
	if [ "$RELOAD" == "yes"  ]; then 
		sudo service freeradius restart	
    fi
	
	fi

    exit 0
else
    exit 1
fi

exit 0
#-t Time Based Token
#-D Allow Reuse (Obligatoire pour le Client Stormshield)
#-S Step Size (Temps entre deux générations de codes)
#-rR Rate Limit (Pas plus de 3 essais en moins de 30 secondes)
#-Q Affiche le QR Code
#-w Permet d autoriser le code d avant ou d'aprés (donc une tolérance de +/- 30 secondes)
#-i Issuer (Titre du Token dans l'appli Authenticator)
#-l Label (Sous-Titre du Token dans l'appli Authenticator)
#Fin du script token.sh

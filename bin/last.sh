#!/bin/bash
#Derniere modification le : 10/06/2022
#Par : Laurent Asselin

#Creation d'un tableau associatif pour lier les entreprises avec les services RADIUS
declare -A ENTREPRISE
CLIENT=""
SERVICE=""

if ! grep -q publisher.sh /etc/crontab ; then #Pas de cluster détectée, on est donc sur des logs radius "standard".

        while read LINE
        do
                if echo "$LINE" | grep -q "^client " >/dev/null 2>&1 ; then
                        SERVICE=$(echo "$LINE" | awk '{print $2}')
                fi
                if echo "$LINE" | grep -q "virtual_server " >/dev/null 2>&1 ; then
                        CLIENT=$(echo "$LINE" | awk '{print $3}' | sed s/_mfa//)
                        if [ -n "$SERVICE" ] && [ -n "$CLIENT" ]; then
                        ENTREPRISE["$SERVICE"]="$CLIENT"
                        fi
                fi
        done < /etc/freeradius/clients.conf

        CORP=""
        LOGIN=""
        OTP_FIREWALL=""
        LAST_CONNECTED=""
        SERVICE=""

        declare -A ALREADY

        #Lecture des logs RADIUS par la fin, et enregistrement de la date de dernière connexion
        tac /var/log/radius.log | grep "Login OK" | while read LINE ;
        do
        set -- $LINE;
                #Récupération de l'entreprise en fonction du service
                SERVICE=${14}
                CORP=${ENTREPRISE[$SERVICE]}

                #Récupération du login
                LOGIN=${11}
                LOGIN=$(echo "${LOGIN,,}")
                LOGIN=$(echo "${LOGIN//[[\]]}")
                LOGIN=${LOGIN%*@*}
		
#Vérification que ce couple n'a pas déjé été trouvé

        if [ "${ALREADY["$CORP$LOGIN"]}" != "OK" ] && [ -n "$CORP" ]; then
                #Récupération de la date
                LAST_CONNECTED="$1 $2 $3 $4 $5"
                LAST_CONNECTED=$(date -d"$LAST_CONNECTED" "+%Y-%m-%d %H:%M:%S")
                #Ecriture de la date de dernière connexion dans la base SQL
                #echo "Login = $LOGIN, Entreprise = $CORP, Date = $LAST_CONNECTED, Service = $SERVICE" >> /tmp/last.log

                php -q /var/www/cron/companies.last.php $LOGIN $CORP $LAST_CONNECTED $SERVICE
                ALREADY["$CORP$LOGIN"]="OK"
        fi
done

else #Cluster détectée, on est donc sur des logs radius "augmenté" avec une colonne en plus.

                while read LINE
        do
                if echo "$LINE" | grep -q "^client " >/dev/null 2>&1 ; then
                        SERVICE=$(echo "$LINE" | awk '{print $2}')
                fi
                if echo "$LINE" | grep -q "virtual_server " >/dev/null 2>&1 ; then
                        CLIENT=$(echo "$LINE" | awk '{print $3}' | sed s/_mfa//)
                        if [ -n "$SERVICE" ] && [ -n "$CLIENT" ]; then
                        ENTREPRISE["$SERVICE"]="$CLIENT"
                        fi
                fi
        done < /etc/freeradius/clients.conf

        CORP=""
        LOGIN=""
        OTP_FIREWALL=""
        LAST_CONNECTED=""
        SERVICE=""

        declare -A ALREADY

        #Lecture des logs RADIUS par la fin, et enregistrement de la date de dernière connexion
        tac /var/log/radius.log | grep "Login OK" | while read LINE ;
        do
        set -- $LINE;
                #Récupération de l'entreprise en fonction du service
                SERVICE=${15}
                CORP=${ENTREPRISE[$SERVICE]}

                #Récupération du login
                LOGIN=${12}
                LOGIN=$(echo "${LOGIN,,}")
                LOGIN=$(echo "${LOGIN//[[\]]}")
                LOGIN=${LOGIN%*@*}

		#Vérification que ce couple n'a pas déjé été trouvé

        if [ "${ALREADY["$CORP$LOGIN"]}" != "OK" ] && [ -n "$CORP" ]; then
                #Récupération de la date
                LAST_CONNECTED="$1 $2 $3 $4 $5"
                LAST_CONNECTED=$(date -d"$LAST_CONNECTED" "+%Y-%m-%d %H:%M:%S")
                #Ecriture de la date de dernière connexion dans la base SQL
                #echo "Login = $LOGIN, Entreprise = $CORP, Date = $LAST_CONNECTED, Service = $SERVICE" >> /tmp/last.log

                php -q /var/www/cron/companies.last.php $LOGIN $CORP $LAST_CONNECTED $SERVICE
                ALREADY["$CORP$LOGIN"]="OK"
        fi
        done
fi

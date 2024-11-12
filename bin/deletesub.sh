#Derniere modification le : 03/08/2021
#Par : Samuel CRETEUR

USAGE="Usage: $0 -H publisher -s subscriber \n\t -H publisher : Indique le nom d'hôte ou l'IP du publisher \n\t -s subscriber : Indique le nom d'hôte ou l'IP du Subscriber \n\t";

while getopts H:s: OPT; do
    case "$OPT" in
      H)
        PUBLISHER="$OPTARG" ;;
          s)
                SUBSCRIBER="$OPTARG" ;;
    [?])
        # got invalid option
        echo -e $USAGE >&2
        exit 1 ;;
    esac
done

if [ "$SUBSCRIBER" = "" ]; then
        echo -e $USAGE >&2
        exit 1
fi

HOSTNAME_SUB=`ssh "${SUBSCRIBER}" 'hostname'`;

#Suppression du répertoire /home 
ssh "${SUBSCRIBER}" "rm -rf /etc/home/";

#Suppression du filtre de log sur le publisher 
rm /etc/rsyslog.d/totp-filtre.conf
systemctl restart rsyslog

#Suppression du filtre de log sur le subscriber
ssh "${SUBSCRIBER}" "rm /etc/rsyslog.d/totp-filtre.conf";
ssh root@"${SUBSCRIBER}" 'systemctl restart rsyslog';

#Suppression de la cron job sur le publisher
sed -i '/publisher.sh -H '$PUBLISHER' -s '$SUBSCRIBER'/d' /etc/crontab;

#Suppression de la cron job sur le subscriber
ssh "${SUBSCRIBER}" "sed -i '/} -e ssh -azu /d' /etc/crontab";

#Suprression de la clé publique de l'utilisateur freeradius du subscriber dans les authorized keys du publisher
sed -i '/freerad@'$HOSTNAME_SUB'/d' /etc/freeradius/.ssh/authorized_keys;

#Suppression de la clé publique de root publisher dans les authorized keys du subscriber
ssh "${SUBSCRIBER}" "sed -i '/root@'$HOSTNAME'/d' /root/.ssh/authorized_keys";


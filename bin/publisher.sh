# !/bin/bash
#Derniere modification le : 01/12/2023
#Par : Laurent Asselin

#Synchro du Publisher vers le Subscriber
USAGE="Usage: $0 -H publisher -s subscriber \n\t -H publisher : Indique le nom d'hôte ou l'IP du publisher \n\t -s subscriber : Indique le nom d'hôte ou l'IP du Subscriber \n\t";
FORCE="u"
MERGE_RADIUS=1;
MERGE_AUTH=1;
RESTART_FREERADIUS=0;
dbexer_dbname="exer_db";
dbexer_username="app_exerotp";
dbexer_password=`cat /etc/mysql/otp.conf`;
date=$(date '+%Y-%m-%d %H:%M:%S');

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

#Vérification si un publisher.sh est déjà en train de tourner ou non
ISEXECUTE=`ps aux | grep "bash /usr/local/bin/publisher.sh"`;
TRUEISEXECUTE=`echo "$ISEXECUTE" | grep "root" | grep -v "grep" | grep -v "sleep" | grep -v "sudo"`;
NUMBERINSTANCES=`echo "$TRUEISEXECUTE" | wc -l`;
if [ "$NUMBERINSTANCES" -gt 2 ];
then
      
      echo "Une instance du programme est déjà en cours d'éxécution. $TRUEISEXECUTE";
      exit 2;
fi

#Vérification si le subscriber est joignable. Si ce n'est pas le cas, on insert un inactif dans la table SQL.
sudo ssh -q -o PasswordAuthentication=no $SUBSCRIBER exit
if [[ $? -eq 0 ]]; then
        SUB_IS_REACHABLE=1;
else
        SUB_IS_REACHABLE=0;
fi

if [[ $SUB_IS_REACHABLE -ne 1 ]]; then
        mysql -u "$dbexer_username" -p"$dbexer_password" "$dbexer_dbname" -e "UPDATE otp_actif SET status = 'inactif' WHERE ip_subscriber='$SUBSCRIBER'";
#Sinon, on lance les synchros
else
        #Vérification sur le fichier clients.conf. S'il est plus ancien sur le subscriber, on met la variable pour redémarrer freeradius à 1.
        FILE1="/etc/freeradius/clients.conf"
        TIME1=$[$(date +%s)-$(stat --printf "%Y" "$FILE1")];
        TIME2BRUT=$(ssh root@"$SUBSCRIBER" "stat -c %Y /etc/freeradius/clients.conf");
        TIME2=$(($(date +%s)-"$TIME2BRUT"));
        TIMEDIFF=$(("$TIME2"-"$TIME1"));
        if [ "$TIMEDIFF" -gt 10 ];
        then
                RESTART_FREERADIUS=1;
        fi
        rsync -e ssh -az -$FORCE --delete-after /home/ root@$SUBSCRIBER:/home/;
        rsync -e ssh -az -$FORCE --delete-after /etc/pam.d/ root@$SUBSCRIBER:/etc/pam.d/
        rsync -e ssh -az -$FORCE --delete-after /etc/pam_ldap*  root@$SUBSCRIBER:/etc/
        rsync -e ssh -az -$FORCE --delete-after --exclude .ssh /etc/freeradius/ root@$SUBSCRIBER:/etc/freeradius/

        #Restart de freeradius si la variable était à 1.
        if [ "$RESTART_FREERADIUS" -eq 1 ]; then
        ssh "${SUBSCRIBER}" "sudo systemctl restart freeradius";
        fi

        #Remontée des logs du sub vers le publisher 
        HOSTNAME_SUB=`ssh "${SUBSCRIBER}" 'hostname' `;
        ssh "${SUBSCRIBER}" "awk '"'$6 = $6 FS "'$HOSTNAME_SUB'"'"' /var/log/radius.log > /tmp/radius.log";
        ssh "${SUBSCRIBER}" 'tar -czf /tmp/"'$SUBSCRIBER'"_log_archive.tar.gz /var/log/auth.log /tmp/radius.log';
        ssh "${SUBSCRIBER}" 'chown freerad:freerad /tmp/"'$SUBSCRIBER'"_log_archive.tar.gz';
        ssh "${SUBSCRIBER}" "su -c 'scp /tmp/${SUBSCRIBER}_log_archive.tar.gz freerad@$PUBLISHER:/tmp/' freerad";


fi


#Ajout du hostname si pas présent dans radius.log et copie des fichiers d'origine pour ensuite les merge  
HOSTNAME_PUB=`hostname`;
awk '{if ($7 ~ / *Auth:*/ || $7 ~ / *Info:*/ || $7 ~ / *ERROR:*/) {$6 = $6 FS "'$HOSTNAME_PUB'"}print}' /var/log/radius.log > /tmp/"$PUBLISHER"_"$SUBSCRIBER"_radius.log;
cp /var/log/auth.log /tmp/"$PUBLISHER"_"$SUBSCRIBER"_auth.log;

#Si les logs ont bien été récupérés, alors on dézip sub log files sur publisher
if [ -f /tmp/"$SUBSCRIBER"_log_archive.tar.gz ]; then
        tar -xzvf /tmp/"$SUBSCRIBER"_log_archive.tar.gz && mv var /tmp/"$SUBSCRIBER"_var && mv tmp /tmp/"$SUBSCRIBER"_tmp;
        #Vérifier le logrotate pour pas avoir doublons de log pour radius.log
        if ls -la /var/log/radius.log.* &> /dev/null; then
                LINES_TO_ADD=`su -c 'comm -1 -3 <(sort /var/log/radius.log.1) <(sort /tmp/"'$SUBSCRIBER'"_tmp/radius.log)' freerad`;
                if [ -z "${LINES_TO_ADD}" ]; then
                        MERGE_RADIUS=0;
                else
                        echo "$LINES_TO_ADD" > /tmp/"$SUBSCRIBER"_tmp/radius.log;
                fi
        fi
        #Vérifier le logrotate pour pas avoir doublons de log pour auth.log
        if ls -la /var/log/auth.log.* &> /dev/null; then
                LINES_TO_ADD=`su -c 'comm -1 -3 <(sort /var/log/auth.log.1) <(sort /tmp/"'$SUBSCRIBER'"_var/log/auth.log)' freerad` ;
                if [ -z "${LINES_TO_ADD}" ]; then
                        MERGE_AUTH=0;
                else
                        echo "$LINES_TO_ADD" > /tmp/"$SUBSCRIBER"_var/log/auth.log;
                fi
        fi
        #Synchro des logs sur le publisher 
        if [ "${MERGE_AUTH}" -eq 1 ]; then
        su -c 'sudo -- sh -c "cat /tmp/\"'$SUBSCRIBER'\"_var/log/auth.log /tmp/\"'$PUBLISHER'\"_\"'$SUBSCRIBER'\"_auth.log | LC_TIME="en_EN.UTF-8" sort -k 1M -k 2n -k 3n | uniq > /var/log/auth.log"' freerad;
        fi

        if [ "${MERGE_RADIUS}" -eq 1 ]; then
        su -c 'sudo -- sh -c "cat /tmp/\"'$SUBSCRIBER'\"_tmp/radius.log /tmp/\"'$PUBLISHER'\"_\"'$SUBSCRIBER'\"_radius.log | LC_TIME="en_EN.UTF-8" sort -k 5n -k 2M -k 3n -k 4n | uniq > /var/log/radius.log"' freerad;
        fi
else
        su -c 'sudo -- sh -c "cat /tmp/\"'$PUBLISHER'\"_\"'$SUBSCRIBER'\"_radius.log | LC_TIME="en_EN.UTF-8" sort -k 5n -k 2M -k 3n -k 4n | uniq > /var/log/radius.log"' freerad;
fi


#Donner droit de lecture sur le fichier auth.log et radius.log car en cas de rotation, il le perd.
chmod +r /var/log/auth.log;
chmod +r /var/log/radius.log;

if [[ $SUB_IS_REACHABLE -eq 1 ]]; then
        ssh "${SUBSCRIBER}" 'chmod +r /var/log/auth.log';
        ssh "${SUBSCRIBER}" 'chmod +r /var/log/radius.log';
        #Suppression des fichires temporaires sur le subscriber
        ssh "${SUBSCRIBER}" 'rm /tmp/"'$SUBSCRIBER'"_log_archive.tar.gz';
        ssh "${SUBSCRIBER}" 'rm /tmp/radius.log';
        #Mise à jour de la base SQL
        mysql -u "$dbexer_username" -p"$dbexer_password" "$dbexer_dbname" -e "UPDATE otp_actif SET status = 'actif' WHERE ip_subscriber='$SUBSCRIBER'";
        mysql -u "$dbexer_username" -p"$dbexer_password" "$dbexer_dbname" -e "UPDATE otp_actif SET last_synchro = '$date' WHERE ip_subscriber='$SUBSCRIBER'";
fi

#Suppression des fichiers temporaires sur le publisher 
rm -f /tmp/"$SUBSCRIBER"_log_archive.tar.gz;
rm -rf /tmp/"$SUBSCRIBER"_var;
rm -rf /tmp/"$SUBSCRIBER"_tmp;
rm -f /tmp/"$PUBLISHER"_"$SUBSCRIBER"_auth.log;
rm -f /tmp/"$PUBLISHER"_"$SUBSCRIBER"_radius.log;







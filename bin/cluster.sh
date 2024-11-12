#Derniere modification le : 10/10/2022
#Par : Laurent ASSELIN

#Synchro du Publisher vers le Subscriber
USAGE="Usage: $0 -H publisher -s subscriber -p password \n\t -H Indique le nom d'hôte ou l'IP du publisher. \n\t -s : Indique le nom d'hôte ou l'IP du Subscriber \n\t -p : Indique le mot de passe root du Subscriber  \n\t"
FORCE="u"
FREERADPASS=`cat /etc/mysql/otp.conf`;

while getopts H:s:p: OPT;
do
    case "$OPT" in
      H) PUBLISHER=${OPTARG} ;;
	  s) SUBSCRIBER=${OPTARG} ;;
	  p) PASSWORD=${OPTARG} ;;

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

if [  "${PASSWORD}" = "" ]; then
	echo -e $USAGE >&2	
	exit 1
fi

if [  "$PUBLISHER" = "" ]; then
	echo -e $USAGE >&2	
	exit 1
fi

#Check que l'ip du publisher n'est pas la même que celle du subscriber
if [  "$PUBLISHER" = "$SUBSCRIBER" ]; then
	echo "Le publisher et le subscriber doivent avoir deux ip différentes." >&2	
	exit 2
fi


#Ajouter la fingerprint du subscriber pour ne pas avoir le message du fingerprint lors de la première connexion.
ALLFINGERPRINT=`ssh-keyscan -H "${SUBSCRIBER}"`;
if [ -z "${ALLFINGERPRINT}" ];
then 
	echo "Le publisher ne parvient pas à joindre le subscriber sur le port 22";
	exit 4;
fi

FINGERPRINT=$(echo "${ALLFINGERPRINT}" | cut -d " " -f3);
VERIFY_FINGERPRINT=`grep "$FINGERPRINT" ~/.ssh/known_hosts`;
[[ -z "${VERIFY_FINGERPRINT}" ]] && echo "${ALLFINGERPRINT}" >> ~/.ssh/known_hosts;

#Check que le mdp du subscriber est bon
if ! sshpass -p "${PASSWORD}" scp /etc/mysql/otp.conf root@"${SUBSCRIBER}":/etc/mysql/otp.conf &> /dev/null; then
        echo "Le mot de passe renseigné n'est pas le bon.";
        exit 5;
fi

#Check que les versions EXER OTP sont identiques
PUBVER=$(sed 's/^Exer OTP v//' /etc/version)
SUBVER=$(sshpass -p "${PASSWORD}" ssh root@"${SUBSCRIBER}" "sed 's/^Exer OTP v//' /etc/version")

if [ "$PUBVER" != "$SUBVER" ];
then 
	echo "Le Publisher et le Subscriber n'ont pas la même version !";
	exit 3;
fi

#Crée le répertoire .ssh pour l’utilisateur freeradius si pas existant.
[[ ! -d /etc/freeradius/.ssh/ ]] && mkdir /etc/freeradius/.ssh/;

#Crée le fichier /root/.ssh/known_hosts si pas existant.
[[ ! -f /etc/freeradius/.ssh/known_hosts ]] && touch /root/.ssh/known_hosts;

#Donne les droits à freeradius sur le répertoire crée par root.
chown -R freerad /etc/freeradius/.ssh/;

#Permet à l’utilisateur freeradius d’avoir un shell bash avec une vérification s'il l'a déjà.
VERIFY_FREERAD_SHELL=`grep "freerad" /etc/passwd | grep "bash"`;

[[ -z "${VERIFY_FREERAD_SHELL}" ]] && sed -i '/freerad:x:107:111/c\freerad:x:107:111::/etc/freeradius:/bin/bash' /etc/passwd;

#Définit le mot de passe pour l’utilisateur freerad comme étant celui de la bdd.
echo freerad:"$(cat /etc/mysql/otp.conf)" | chpasswd;

#Copie le fichier otp.conf vers le subscriber pour que le mot de passe de la bdd soit le même sur les deux serveurs. 
sshpass -p "${PASSWORD}" scp /etc/mysql/otp.conf root@"${SUBSCRIBER}":/etc/mysql/otp.conf;


#Crée le répertoire .ssh pour l’utilisateur freeradius sur le subscriber s'il n'existe pas.
if sshpass -p "${PASSWORD}" ssh root@"${SUBSCRIBER}" '[ ! -d /etc/freeradius/.ssh/ ]';
then
	sshpass -p "${PASSWORD}" ssh root@"${SUBSCRIBER}" 'mkdir /etc/freeradius/.ssh/';
else
	sshpass -p "${PASSWORD}" ssh root@"${SUBSCRIBER}" 'rm -R /etc/freeradius/.ssh/';
	sshpass -p "${PASSWORD}" ssh root@"${SUBSCRIBER}" 'mkdir /etc/freeradius/.ssh/';
fi

#Crée le fichier known hosts pour l'user freerad sur le subscriber s'il n'existe pas.
if sshpass -p "${PASSWORD}" ssh root@"${SUBSCRIBER}" '[ ! -f /etc/freeradius/.ssh/known_hosts ]'; then
	sshpass -p "${PASSWORD}" ssh root@"${SUBSCRIBER}" 'touch /etc/freeradius/.ssh/known_hosts';
fi

#Donne les droits à freeradius sur le répertoire crée sur le subscriber.
sshpass -p "${PASSWORD}" ssh root@"${SUBSCRIBER}" 'chown -R freerad /etc/freeradius/.ssh/';

#Permet à l’utilisateur freerad sur le subscriber d’avoir un shell bash s'il n'en a pas déjà un
VERIFY_FREERAD_SHELL_SUBSCRIBER= sshpass -p "${PASSWORD}" ssh root@"${SUBSCRIBER}" 'grep "freerad" /etc/passwd | grep "bash"';
[[ -z "${VERIFY_FREERAD_SHELL_SUBSCRIBER}" ]] && sshpass -p "${PASSWORD}" ssh root@"${SUBSCRIBER}" 'sed -i '/freerad:x:107:111/c\freerad:x:107:111::/etc/freeradius:/bin/bash' /etc/passwd';

#Définit le mot de passe pour l’utilisateur freerad comme étant celui de la bdd pour le subscriber.
sshpass -p "${PASSWORD}" ssh root@"${SUBSCRIBER}" 'echo freerad:"$(cat /etc/mysql/otp.conf)" | chpasswd';

#Supprime clé privée de l'utilisateur freeradius sur le subscriber si existe.
if sshpass -p "${PASSWORD}" ssh root@"${SUBSCRIBER}" '[ -f /etc/freeradius/.ssh/id_rsa ]'; then
	sshpass -p "${PASSWORD}" ssh root@"${SUBSCRIBER}" 'rm -rf /etc/freeradius/.ssh/id_rsa';
fi

#Génération de paire de clés pour l’utilisateur freerad avec pour passphrase « » sur le subscriber.
sshpass -p "${FREERADPASS}" ssh freerad@"${SUBSCRIBER}" 'ssh-keygen -t rsa -q -f "/etc/freeradius/.ssh/id_rsa" -N ""';

#Ajouter la fingeroprint du publisher pour ne pas avoir le message du fingerprint lors de la première connexion.
ALLFINGERPRINT_PUB=`sshpass -p "${PASSWORD}" ssh root@"${SUBSCRIBER}" 'ssh-keyscan -H "'${PUBLISHER}'"'`;
FINGERPRINT_PUB=$(echo "${ALLFINGERPRINT_PUB}" | cut -d " " -f3);
VERIFY_FINGERPRINT_PUB=`sshpass -p "${PASSWORD}" ssh root@"${SUBSCRIBER}" 'grep "${FINGERPRINT_PUB}" /etc/freeradius/.ssh/known_hosts'`;
[[ -z "${VERIFY_FINGERPRINT_PUB}" ]] && sshpass -p "${PASSWORD}" ssh root@"${SUBSCRIBER}" 'echo "'"$ALLFINGERPRINT_PUB"'" >> /etc/freeradius/.ssh/known_hosts';

#Ajouter la clé publique de l'utilisateur freeradius du subscriber dans les authorized keys du publisher si jamais elle n'y est pas déjà.
SUB_PUB_KEY=`sshpass -p "${PASSWORD}" ssh root@"${SUBSCRIBER}" 'cat /etc/freeradius/.ssh/id_rsa.pub'`;
VERIFY_PUB_KEY_SUB=`grep "${SUB_PUB_KEY}" /etc/freeradius/.ssh/authorized_keys`;
[[ -z "${VERIFY_PUB_KEY_SUB}" ]] && echo "${SUB_PUB_KEY}" >> /etc/freeradius/.ssh/authorized_keys;

#Bloquer l’authentification au compte freerad sur le subscribeur par mot de passe excepté pour root
sshpass -p "${PASSWORD}" ssh root@"${SUBSCRIBER}" 'passwd -l freerad';

#Bloquer l’authentification au compte freerad sur le publisher par mot de passe excepté pour root
passwd -l freerad;

#Création de paire de clés si n'existe pas
if [ ! -f /root/.ssh/id_rsa ]
then 
	ssh-keygen -t rsa -q -f "/root/.ssh/id_rsa" -N "";
fi

#Copie de la clé publique de root sur le subscribeur 
sshpass -p "${PASSWORD}" ssh-copy-id -i /root/.ssh/id_rsa.pub root@"${SUBSCRIBER}";

#Première synchro 
rsync -e ssh -az -$FORCE --delete-after /home/ root@$SUBSCRIBER:/home/
rsync -e ssh -az -$FORCE --delete-after /etc/pam.d/ root@$SUBSCRIBER:/etc/pam.d/
rsync -e ssh -az -$FORCE --delete-after /etc/pam_ldap*  root@$SUBSCRIBER:/etc/
rsync -e ssh -caz -$FORCE --delete-after --exclude .ssh /etc/freeradius/ root@$SUBSCRIBER:/etc/freeradius/ 

#Activer les logs de  sur le publisher si ce n'est pas déjà fait 
VERIFY_LOG_CRON=`grep "#cron" /etc/rsyslog.conf`;
if [ ! -z "${VERIFY_LOG_CRON}" ]
then 
	sed -i 's/^#cron/cron/g' /etc/rsyslog.conf;
	service rsyslog restart;
	service cron restart;
 fi

 #Activer les logs de  sur le publisher si ce n'est pas déjà fait
VERIFY_LOG_CRON=`ssh "$SUBSCRIBER" 'grep "#cron" /etc/rsyslog.conf'`;
if [ ! -z "${VERIFY_LOG_CRON}" ]
then
        ssh "$SUBSCRIBER" 'sed -i "s/^#cron/cron/g" /etc/rsyslog.conf';
        ssh "$SUBSCRIBER" 'service rsyslog restart';
        ssh "$SUBSCRIBER" 'service cron restart';
fi

#Donner les droits à l'utilisateur freerad sur le fichier de log cron
chown freerad:freerad /var/log/cron.log;

#Test port ssh ouvert publisher
ssh "${SUBSCRIBER}" "timeout 3 bash -c '</dev/tcp/$PUBLISHER/22'";
if [  $? -ne 0 ]; then 
	bash /usr/local/bin/deletesub.sh -H "$PUBLISHER" -s "$SUBSCRIBER";
	echo "Le subscriber ne parvient pas à joindre le publisher sur le port 22."
	exit 7
fi

#Test bidirectionnalité SSH
ssh "${SUBSCRIBER}" "su -c 'ssh -q -o PasswordAuthentication=no $PUBLISHER exit' freerad";
if [  $? -ne 0 ]; then 
	bash /usr/local/bin/deletesub.sh -H "$PUBLISHER" -s "$SUBSCRIBER";
	echo "La bidirectionnalité SSH n'est pas effective."
	exit 8
fi

#Initialisation de la variable sleep_time 
SLEEP_TIME=0;

#Ajouter la tâche cron pour la synchro toutes les 5 minutes si elle n'y est pas déjà sur le publisher
VERIFY_CRON=`grep "/usr/local/bin/publisher.sh -H $PUBLISHER -s $SUBSCRIBER" /etc/crontab`;
if [ -z "${VERIFY_CRON}" ]
then 
	NUMBER_SUB=`grep "/usr/local/bin/publisher.sh -H" /etc/crontab | wc -l`;
    SLEEP_TIME=$((20*NUMBER_SUB));
    echo "*/5 * * * * root sleep $SLEEP_TIME; /bin/bash /usr/local/bin/publisher.sh -H $PUBLISHER -s $SUBSCRIBER" >> /etc/crontab;
else
	echo "L'actif actif est déjà mis en place entre ces deux VM.";
	exit 6
fi

#Ajouter la tâche cron pour la synchro toutes les 5 minutes si elle n'y est pas déjà sur le subscriber
VERIFY_CRON_SUB=`ssh "${SUBSCRIBER}" 'grep "-e ssh -azu /home/ freerad@" /etc/crontab'`;
if [ -z "${VERIFY_CRON_SUB}" ]
then
        ssh "${SUBSCRIBER}" 'echo "*/5 * * * * freerad sleep '"$SLEEP_TIME"'; rsync --existing --exclude={'"'otp.license'"'} -e ssh -azu /home/ freerad@'"$PUBLISHER"':/home/" >> /etc/crontab';
else
		sed -i -n -e :a -e '1,1!{P;N;D;};N;ba' /etc/crontab;
        echo "L'actif actif est déjà mis en place entre ces deux VM.";
        exit 6
fi

#Ajout filtre rsyslog publisher si pas présent
if [ ! -f /etc/rsyslog.d/totp-filtre.conf ]; then
	cat << 'EOF' > /etc/rsyslog.d/totp-filtre.conf
:msg, contains, "session opened" ~ /var/log/auth.log
:msg, contains, "Accepted password" ~ /var/log/auth.log
:msg, contains, "session closed" ~ /var/log/auth.log
:msg, contains, "Received disconnect from" ~ /var/log/auth.log
:msg, contains, "Removed session" ~ /var/log/auth.log
:msg, contains, "New session" ~ /var/log/auth.log
:msg, contains, "Disconnected" ~ /var/log/auth.log
:msg, contains, "Accepted publickey for" ~ /var/log/auth.log
:msg, contains, "cron:session" ~ /var/log/auth.log
:msg, contains, "pam_unix(sshd:session):" ~ /var/log/auth.log
:msg, contains, "pam_unix(sudo:session):" ~ /var/log/auth.log
:msg, contains, "systemd-logind" ~ /var/log/auth.log
:msg, contains, "sshd" ~ /var/log/auth.log
:msg, contains, "passwd" ~ /var/log/auth.log
:msg, contains, "Started Session" ~ /var/log/auth.log
:msg, contains, "logged out. Waiting for processes to exit" ~ /var/log/auth.log
:msg, contains, "used by new audit session, ignoring" ~ /var/log/auth.log
:programname, isequal, "su" ~ /var/log/auth.log
:programname, isequal, "systemd" ~ /var/log/daemon.log

EOF
	systemctl restart rsyslog
fi 

#Ajout filtre rsyslog subscriber si pas présent
if ssh root@"${SUBSCRIBER}" '[ ! -f /etc/rsyslog.d/totp-filtre.conf ]'; then
        ssh root@"${SUBSCRIBER}" 'cat << 'EOF' > /etc/rsyslog.d/totp-filtre.conf
:msg, contains, "session opened" ~ /var/log/auth.log
:msg, contains, "Accepted password" ~ /var/log/auth.log
:msg, contains, "session closed" ~ /var/log/auth.log
:msg, contains, "Received disconnect from" ~ /var/log/auth.log
:msg, contains, "Removed session" ~ /var/log/auth.log
:msg, contains, "New session" ~ /var/log/auth.log
:msg, contains, "Disconnected" ~ /var/log/auth.log
:msg, contains, "Accepted publickey for" ~ /var/log/auth.log
:msg, contains, "cron:session" ~ /var/log/auth.log
:msg, contains, "pam_unix(sshd:session):" ~ /var/log/auth.log
:msg, contains, "pam_unix(sudo:session):" ~ /var/log/auth.log
:msg, contains, "systemd-logind" ~ /var/log/auth.log
:msg, contains, "sshd" ~ /var/log/auth.log
:msg, contains, "passwd" ~ /var/log/auth.log
:msg, contains, "Started Session" ~ /var/log/auth.log
:msg, contains, "logged out. Waiting for processes to exit" ~ /var/log/auth.log
:msg, contains, "used by new audit session, ignoring" ~ /var/log/auth.log
:programname, isequal, "su" ~ /var/log/auth.log
:programname, isequal, "systemd" ~ /var/log/daemon.log

EOF';
	ssh root@"${SUBSCRIBER}" 'systemctl restart rsyslog';
fi

#Supprimer last.sh sur le subscriber si existe
if ssh root@"${SUBSCRIBER}" '[ -f /etc/cron.d/last ]'; then
        ssh root@"${SUBSCRIBER}" 'rm /etc/cron.d/last';
fi

#Couper serveur web sub et empêcher son redémarrage à chaque reboot
ssh "${SUBSCRIBER}" 'systemctl stop apache2';
ssh "${SUBSCRIBER}" 'systemctl disable apache2';

#Couper bdd sql et empêcher redémarrage 
ssh "${SUBSCRIBER}" 'systemctl stop mariadb';
ssh "${SUBSCRIBER}" 'systemctl disable mariadb';
ssh "${SUBSCRIBER}" '/etc/init.d/mysql stop';
ssh "${SUBSCRIBER}" 'systemctl disable mysql';

#Couper service Postfix et empêcher redémarrage
ssh "${SUBSCRIBER}" 'systemctl stop postfix';
ssh "${SUBSCRIBER}" 'systemctl disable postfix';

#Redémarrer service freeradius
ssh "${SUBSCRIBER}" 'systemctl restart freeradius';

#Force la première synchro
ssh "${SUBSCRIBER}" 'rm /etc/freeradius/clients.conf';
/bin/bash /usr/local/bin/publisher.sh -H $PUBLISHER -s $SUBSCRIBER




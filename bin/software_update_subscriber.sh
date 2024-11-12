#Derniere modification le : 24/08/2021
#Par : Samuel CRETEUR

USAGE="Usage: $0 -s subscriber -u update_file \n\t -s subscriber : Indique le nom d'hôte ou l'IP du Subscriber \n\t -u update_file : Indique le script de mise à jour \n\t";

while getopts s:u: OPT; do
    case "$OPT" in
      s)
        SUBSCRIBER="$OPTARG" ;;
      u)
        UPDATE_FILE="$OPTARG" ;;
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

if [ "$UPDATE_FILE" = "" ]; then
        echo -e $USAGE >&2
        exit 1
fi

#mise à jour logicielle

#Verification de la Signature
/usr/local/bin/maj_verify $4
if [ $? -ne 0 ]; then
    echo "Corrupted signature"
        sudo rm -rf /var/www/tmp/*
    exit 84
fi

#send zip 
scp $4 root@$SUBSCRIBER:$4;

#unzip
ssh "${SUBSCRIBER}" 'unzip -q "'$4'" -d /var/www/tmp'
if [ $? -ne 0 ]; then
    echo "fail 5"
        ssh "${SUBSCRIBER}" 'sudo rm -rf /var/www/tmp/*'
    exit 84
fi

ssh "${SUBSCRIBER}" 'chmod +x /var/www/tmp/update_it.sh';
ssh "${SUBSCRIBER}" 'bash /var/www/tmp/update_it.sh';

#Nettoyage
ssh "${SUBSCRIBER}" 'rm -rf /var/www/tmp/*'

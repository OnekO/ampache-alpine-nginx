#!/bin/sh
STARTED=".STARTED"
if [ ! -e /media/$STARTED ]; then
    touch /media/$STARTED
    if [ $FORCE_INSTALL == "true" ]; then
        php bin/install/install.php -h $MYSQL_HOST -d $MYSQL_DB -u $MYSQL_USER -p $MYSQL_PASSWORD --database-port $MYSQL_PORT -U $MYSQL_ROOT_USER -P $MYSQL_ROOT_PASSWORD --force
    else
        php bin/install/install.php -h $MYSQL_HOST -d $MYSQL_DB -u $MYSQL_USER -p $MYSQL_PASSWORD --database-port $MYSQL_PORT -U $MYSQL_ROOT_USER -P $MYSQL_ROOT_PASSWORD 
    fi
    php bin/install/update_db.inc -u
    php bin/install/add_user.inc -u $AMPACHE_USER -p $AMPACHE_PASSWORD
fi

/usr/bin/supervisord -n -c /etc/supervisord.conf 

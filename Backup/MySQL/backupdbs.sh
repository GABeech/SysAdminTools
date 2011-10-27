#!/bin/sh

##########################################################################
## MySQL Backup Script +++ 12/16/2003 +++ Timothy Lorens
##########################################################################

BACKUP_TMP="/tmp/"
BACKUP_PATH="/opt/MySQLBackups/"
DATE=`/bin/date +%Y%m%d`
SERVER=localhost
USER="mysqluser"
PASS="mysqlpass"
ARGS="--skip-column-names -B -r"
DBCACHE=$SERVER.db      # localhost.db

cd $BACKUP_TMP

echo "show databases" | mysql $ARGS -h $SERVER -u $USER -p$PASS > $DBCACHE

for db in `cat $DBCACHE`
do
        TBLCACHE=$SERVER.$db.tbl # localhost.clockwork.tbl
        echo "show tables from \`$db\`" | mysql $ARGS -h $SERVER -u $USER -p$PASS > $TBLCACHE

        for tbl in `cat $TBLCACHE`
        do
                ## echo "Writing: $db.$tbl.dmp"
                mysqldump -C -c --allow-keywords --add-drop-table -Q $db $tbl -h $SERVER -u $USER -p$PASS > $db.$tbl.dmp
                echo "Archived: $db.$tbl.gz"
                gzip $db.$tbl.dmp
        done
        rm $TBLCACHE
done
rm $DBCACHE

echo "Archiving as: $BACKUP_PATH$DATE-mysql.tar.bz2"
tar -jcf $BACKUP_PATH$DATE-mysql.tar.bz2 *.gz

echo "Cleaning up!"
rm *.gz
rm *.db
rm *.tbl


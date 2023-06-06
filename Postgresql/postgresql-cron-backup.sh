#!/bin/bash

WORK_PATH="/var/lib/postgresql/backups/database/"
BACKUP_PATH="${WORK_PATH}`date +\%Y-\%m-\%d`/"

if ! [ -d "$BACKUP_PATH" ]
then
        echo "Creating directory $BACKUP_PATH"
        mkdir "$BACKUP_PATH"
fi

for dbname in `echo "SELECT datname FROM pg_database;" | psql | tail -n +3 | head -n -2 | egrep -v 'template0|template1'`; do
    pg_dump $dbname | gzip > $BACKUP_PATH/$dbname-$(date "+%Y-%m-%d").sql.gz
done;

#!/bin/bash

. `dirname $0`/config.ini

BACKUP_DIR="${BACKUP_DIR}/mysql/${PROJECT}"

# Create dir for backups
if [ ! -d "$BACKUP_DIR" ]; then
  echo "::=> Directory does not exist :: $BACKUP_DIR"
  mkdir -p $BACKUP_DIR
fi

# Create backup
/usr/bin/mysqldump --lock-tables=false $db $IGNOR | gzip -c > "$BACKUP_DIR/$db-$DATE.sql.gz"

/usr/bin/mysqldump --no-data --lock-tables=false $db $SCHEMAS | gzip -c >> "$BACKUP_DIR/$db-$DATE.sql.gz"

cd $BACKUP_DIR
md5sum $db-$DATE.sql.gz >> MD5SUMS

# Copy backups to remote host
#scp $BACKUP_DIR/MD5SUMS                         $BACKUP_HOST:$BACKUP_DIR/
#scp $BACKUP_DIR/$db-$DATE.sql.gz        $BACKUP_HOST:$BACKUP_DIR

find $BACKUP_DIR -name "*.sql.gz" -mtime +$N | xargs rm -f

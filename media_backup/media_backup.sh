#!/bin/bash

. `dirname $0`/config.ini

BACKUP_DIR="${BACKUP_DIR}/media/${PROJECT}"

# Create dir for backups
if [ ! -d "$BACKUP_DIR" ]; then
  echo "::=> Directory does not exist :: $BACKUP_DIR"
  mkdir -p $BACKUP_DIR
fi

cd $PROJECT_DIR

# Create backup
tar -czhvf $BACKUP_DIR/media.$PROJECT.$DATE.tar.gz media/

# Copy backups to remote host
scp $BACKUP_DIR/media.$PROJECT.$DATE.tar.gz  $BACKUP_HOST:$BACKUP_DIR/

#Check backup
LAST_BACKUP_SIZE=`ls -la ${BACKUP_DIR}/*tar.gz | tail -1 | awk '{print $5}'`
PREV_BACKUP_SIZE=`ls -la ${BACKUP_DIR}/*tar.gz | tail -2 | head -1 | awk '{print $5}'`
PERCENT=`echo "scale=4 ; $LAST_BACKUP_SIZE / $PREV_BACKUP_SIZE * 100" | bc`

if [ -e "$BACKUP_DIR/media.$PROJECT.$DATE.tar.gz" ]; then
    zabbix_sender -z z.oggy.co -s "${HOST}" -k "media.backup.exists" -o 0 > /dev/null
    zabbix_sender -z z.oggy.co -s "${HOST}" -k "media.backup.increases" -o "${PERCENT}" > /dev/null
fi

# Delete backups after $N days
find $BACKUP_DIR/ -name media.$PROJECT.*.tar.gz -type f -mtime +$N -print0 | xargs -0 rm -f

#!/bin/sh
#

#--- Start Postgres Backup mode
#--- (generate checkpoint info into file and archive it to archive log)
echo "Postgres Backup checkpoint start"
/var/lib/pgsql/maint/backup_start.pl
if [ $? -gt 0 ]
then
        echo "Postgres Backup checkpoint failed - backup aborted"
        exit 1
fi
echo "Postgres Backup checkpoint completed"

#--- Insert script to do SnapVault here...

#--- Terminate Postgres Backup mode
#--- (starts next WAL segment and archives last one)
echo "Postgres Backup finish step started"
/var/lib/pgsql/maint/backup_stop.pl
if [ $? -gt 0 ]
then
        echo "Postgres Backup finish step failed"
        exit 1
fi
echo "Postgres Backup finish step completed"


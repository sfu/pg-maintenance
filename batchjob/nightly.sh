#!/bin/sh
#
#---------------------------------------
#--- Commands to execute once each night
#---------------------------------------
#---
#--- Delete older files in assorted directories -- keeping x number of them
#---
/var/lib/pgsql/maint/keepfiles.pl "/dbbackup" '^dumpfile' 2
/var/lib/pgsql/maint/keepfiles.pl "/var/lib/pgsql/maint/logmaint" '^backupfiles' 2

#--- Start Postgres Backup mode
#--- (generate checkpoint info into file and archive it to archive log)
#echo "Postgres Backup checkpoint start"
/var/lib/pgsql/maint/backup_start.pl
if [ $? -gt 0 ]
then
        #echo "Postgres Backup checkpoint failed - backup aborted"
        exit 1
fi
#echo "Postgres Backup checkpoint completed"

#--- Copy/compress database files to /dbbackup location
/var/lib/pgsql/maint/backupfiles.pl

#--- Terminate Postgres Backup mode
#--- (starts next WAL segment and archives last one)
#echo "Postgres Backup finish step started"
/var/lib/pgsql/maint/backup_stop.pl
if [ $? -gt 0 ]
then
        #echo "Postgres Backup finish step failed"
        exit 1
fi
#echo "Postgres Backup finish step completed"


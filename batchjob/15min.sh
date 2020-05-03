#!/bin/sh
#
#---------------------------------------------
#--- Commands to execute once every 15 minutes
#---------------------------------------------
#---
#--- Look in Postgres server log file for any new errors/warnings 
/var/lib/pgsql/maint/logcheck.pl 'postgresql-%a.log'

#--- Look in cron job log for any errors/warnings
/var/lib/pgsql/maint/checkcronlog.pl

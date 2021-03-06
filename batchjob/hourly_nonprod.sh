#!/bin/sh
#
#-------------------------------------
#--- Commands to execute once per hour
#-------------------------------------
#---
#--- Delete older files in assorted directories when more than x days old
/var/lib/pgsql/maint/deloldfiles.pl "/var/lib/pgsql/maint/cronlog" 'log$' 2
/var/lib/pgsql/maint/deloldfiles.pl "/var/lib/pgsql/maint/logmaint" 'lock$' 1
/var/lib/pgsql/maint/deloldfiles.pl "/var/lib/pgsql/maint/temp" '.' 2

#--- Delete older files in archive log directory keeping 0 days, 1 hour of them
/var/lib/pgsql/maint/deloldfiles.pl "/dbarchive" '^[0-9]' 0 1

#--- Check that there is enough disk space for database
/var/lib/pgsql/maint/checkdisk.pl /data/dbdata 10000000
/var/lib/pgsql/maint/checkdisk.pl /dbarchive 5000000

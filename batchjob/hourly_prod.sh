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

#---
/var/lib/pgsql/maint/deloldfiles.pl "/dbarchive" '^[0-9]' 4

#--- Check that there is at least 15 gig for data cluster directory
/var/lib/pgsql/maint/checkdisk.pl /data/dbdata 15000000
/var/lib/pgsql/maint/checkdisk.pl /dbarchive 5000000

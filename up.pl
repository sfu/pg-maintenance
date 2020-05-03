#!/usr/bin/perl
use strict;

#--- Set up libraries
my $fname=$0;
my $path="";
if ($fname =~ /^(.+\/)[^\/]+$/) { $path=$1; }

#--- Specify variables for this instance
require "${path}global.pl";

#--- Utilities library under main instance
require "${main::SCRIPT_MAIN}/utilities.pl";

#--- Exit if downtime is on
if (&downtimecheck()) {exit;}

#--- Direct any output to a log
&logout();

#--- Get current date/time display
open(COMM,"${main::SYSBIN}/date '+%b %e, %Y %H:%M:%S'|");
my $datedisplay=<COMM>; chop $datedisplay;
close(COMM);

#--- Check that PID file exists
my $pidfile = "${main::DBDATADIR}/postmaster.pid";
if (!(-e "${pidfile}"))
{
  #--- If PID file does not exist, then:
  #--- - Write info about it to status file
  #--- - But DON'T "touch" other special status file
  open(OUTPUT,">${main::SCRIPT_LOG}/up_info.log");
  print OUTPUT "ERROR: The up.pl job on ${main::SERVERNAME} found that the Postgres server","\n";
  print OUTPUT "       PID file ${pidfile} appears to be missing","\n";
  print OUTPUT "       Check that the server is running properly. It probably needs a reboot","\n";
  print OUTPUT "       Date/Time: ${datedisplay}","\n";
  close(OUTPUT);
  exit 1;
}

##--- Connect and issue command
my $errorflag='yes';
my $line;
open(COMM,"${main::PGBIN}/psql -c \"select 'server is up'\"|");
while($line=<COMM>)
{
  chop $line;
  if ($line =~ /server is up/)
  {
    $errorflag='no';
  }
}
close(COMM);

#---
if ($errorflag eq "yes")
{
  #--- If error occurred while connecting to Postgres, then:
  #--- - Write info about it to status file
  #--- - But DON'T "touch" other special status file
  open(OUTPUT,">${main::SCRIPT_LOG}/up_info.log");
  print OUTPUT "WARNING: The up.pl job on ${main::SERVERNAME} was NOT able to connect to Postgres","\n";
  print OUTPUT "         Check that the server is running properly. It may need a reboot","\n";
  print OUTPUT "         Date/Time: ${datedisplay}","\n";
  close(OUTPUT);
}
else
{
  #--- If successful connecting to the database server, then:
  #--- - Do a "touch" on special status file
  system "${main::SYSBIN}/touch ${main::SCRIPT_LOG}/up_status.log";
  #--- Also Write "success" message to status file
  open(OUTPUT,">${main::SCRIPT_LOG}/up_info.log");
  print OUTPUT "SUCCESS: The up.pl job on ${main::SERVERNAME} was able to connect to Postgres","\n";
  print OUTPUT "         Date/Time: ${datedisplay}","\n";
  close(OUTPUT);
}

exit;


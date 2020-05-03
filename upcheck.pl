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

#--- Get number of minutes to check for status of
#--- "up" status log file
my $timecheck=$ARGV[0];
#--- If argument not specified, set it to default of 10 minutes
if ($timecheck eq '') {$timecheck=10;}

#--- Exit if downtime is on
if (&downtimecheck()) {exit;}

#--- Direct any output to a log
&logout();

#--- If the "up" status file was last changed less than x minutes ago,
#--- then we are happy -- simply exit
my $chktime=time() - ($timecheck * 60);
my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,
    $blksize,$blocks) = stat("${main::SCRIPT_LOG}/up_status.log");
#print "\n";
#print " chktime:$chktime\n";
#print " mtime:$mtime\n";
my $mtime_status=$mtime;
if ($mtime_status > $chktime)
{
  exit;
}

#--- Otherwise get last change time for info file
($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,
 $blksize,$blocks) = stat("${main::SCRIPT_LOG}/up_info.log");

my $subject='';
my $line;
#--- If info file is more recently written to than status log file
#--- it means that the up.pl program failed to connect to the
#--- server and the up_info log file has information about it
if ($mtime_status < $mtime)
{
  $subject="${main::SERVERNAME} - Postgres server may have died";
  &emailopen($main::ADMINADDR,$main::ADMINISTRATOR,$subject);
  print MESSAGE "\n";
  print MESSAGE "It appears that Postgres on ${main::SERVERNAME} may have died.\n\n";
  print MESSAGE "Please check the status and possibly reboot the server.\n\n";
  print MESSAGE "Info from the file: ${main::SCRIPT_LOG}/up_info.log:","\n\n";
  open(INPUT,"<${main::SCRIPT_LOG}/up_info.log");
  while($line=<INPUT>)
  {
    print MESSAGE $line;
  }
  close(INPUT);
}

#--- Otherwise Postgres is likely hung as the up.pl program did not return
#--- a timely result
else
{
  $subject="${main::SERVERNAME} - Postgres server may be hung";
  &emailopen($main::ADMINADDR,$main::ADMINISTRATOR,$subject);
  print MESSAGE "\n";
  print MESSAGE "It appears that Postgres on ${main::SERVERNAME} may be hung.\n\n";
  print MESSAGE "Please check the status and possibly reboot the server.\n\n";
  print MESSAGE "See following files on the server for info on when up.pl last ran:\n";
  print MESSAGE "  ${main::SCRIPT_LOG}/up_status.log","\n";
  print MESSAGE "  ${main::SCRIPT_LOG}/up_info.log","\n";
}
close(MESSAGE);

exit;


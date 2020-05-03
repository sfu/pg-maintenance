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

#---
my $dumpstem=$ARGV[0];
my $nocompress=$ARGV[1];

if ($dumpstem eq '')
{
  $dumpstem='dumpfile';
}

my $dumpsuffix='tar.gz';
if ($nocompress ne '')
{
  $dumpsuffix='tar';
}

my $dumpdir=$main::DBBACKUPDIRMAIN;

my $errorflag='no';
my $timestart=time();

#--- 
my $TEMPFILE="${main::SCRIPT_TEMP}/backupfiles_$$.txt";
my $LOGFILE="${main::SCRIPT_LOG}/backupfiles_$$.txt";

#---
#--- Generate name of next available dumpfile name for all databases
my $dumpfile = &genfilename($dumpdir,$dumpstem,$dumpsuffix);

$dumpfile=~s/${dumpsuffix}$//;
my $dumpfilechk = &genfilename($dumpdir,$dumpstem,$dumpsuffix);
if ($dumpfilechk gt $dumpfile) {$dumpfile=$dumpfilechk;}
$dumpfile="${dumpdir}/${dumpfile}";

#--- Sanity check: make sure file does not already exist for some reason
my $chk;
$chk=open(CHECK,"<${dumpfile}");
close(CHECK);
if ($chk ==1)
{
  print "**Error: generated dump file name ${dumpfile} already exists.\n";
  print "         I quit!\n";
  exit;
}

#------------------------------------------------------------------------
#--- Set it up so that all diagnostic output goes to the LOGFILE
#------------------------------------------------------------------------
close(STDOUT);
close(STDERR);
$chk=system "${main::SYSBIN}/touch ${LOGFILE}";
open(STDOUT,">>${LOGFILE}");
open(STDERR,">>${LOGFILE}");

#------------------------------------------------------------------------
#--- tar and compress the data cluster directory to backup location
#------------------------------------------------------------------------

#---
print "\n";
print '='x75,"\n";
print '== Full backup of all files in the Postgres database cluster',"\n";
print '='x75,"\n";

#--- Compress the dump unless "nocompress" is specified
my $timespent;
if ($nocompress ne 'nocompress')
{
  print "\n";
  print "${main::SYSBIN}/tar -zcf ${dumpfile} ${main::DBDATADIR}","\n";
  $chk=system "${main::SYSBIN}/tar -zcf ${dumpfile} ${main::DBDATADIR}";

  $timespent = time() - $timestart;
  print "**\n";
  printf ("** Total time (dump/compress/save): %.2f min\n",$timespent/60.0);

  if ($chk > 0)
  {
    print "**\n";
    print "**Error return code of $chk returned. See messages above.\n";
#    print "**      I quit!\n";
    print "**\n";
    $errorflag='yes';
  }
}

#---
close(STDOUT);
close(STDERR);

#--- Now e-mail the result of doing the backups
my $subject='';
if ($errorflag eq 'no')
{
  $subject="${main::SERVERNAME} Postgres backup files";
}
else
{
  $subject="${main::SERVERNAME} Postgres backup files **WARNING**";
}
&emailopen($main::ADMINADDR,$main::ADMINISTRATOR,$subject);
open(INPUT,"<$LOGFILE");
my $line;
while($line=<INPUT>)
{
  print MESSAGE $line;
}
close(INPUT);
close(MESSAGE);

exit 0;


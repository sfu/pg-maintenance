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

#--- Direct any output to a log
&logout();

my $TEMPFILE="${main::SCRIPT_TEMP}/backup_start_$$.txt";

##--- Connect and issue command
my $cmd="${main::PGBIN}/psql -c \"SELECT pg_start_backup('/dbbackup')\" > ${TEMPFILE}";
system $cmd;

#--- Parse the output to check for a pattern like this:
# pg_start_backup
#-----------------
# 1/4400B4A8
#(1 row)

open(INPUT,"<$TEMPFILE");
my $line;
my $goodlines=0;
my $subject;

#--- Check line 1
$line=<INPUT>; chop $line;
if ($line =~ /^\s*pg_start_backup\s*$/) {$goodlines++;}

#--- Check line 3
$line=<INPUT>;
$line=<INPUT>; chop $line;
if ($line =~ /^\s*[0-9A-F]+\/[0-9A-F]+\s*$/) {$goodlines++;}

close(INPUT);

#--- If 2 good lines found, then exit with zero return code
if ($goodlines == 2)
{
  system "${main::SYSBIN}/rm -f $TEMPFILE";
  exit 0;
}

#--- Otherwise send notification and exit with nonzero return code
else
{
  $subject="${main::SERVERNAME} Postgres - backup_start failure";
  #--- This opens e-mail via unit MESSAGE
  &emailopen($main::ADMINADDR,$main::ADMINISTRATOR,$subject);

  print MESSAGE "\n";
  print MESSAGE "Error running backup_start.pl script to establish Postgres\n";
  print MESSAGE "checkpoint during backup procedure\n";
  print MESSAGE "\n";
  open(INPUT,"<$TEMPFILE");
  while($line=<INPUT>)
  {
    print MESSAGE $line;
  }
  close(INPUT);
  close(MESSAGE);
  exit 1;
}

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

#--- Get arguments
my $logfile=$ARGV[0];
my $logdir=$ARGV[1];

#--- Set default location of log directory if it was
#--- not specified
if ($logdir eq '')
{
  if ($main::DBERRORDIR ne '')
  {
    $logdir=$main::DBERRORDIR;
  }
  else
  {
    $logdir=$main::DBDATADIR;
  }
}

#--- Direct any output to a log
&logout();

#--- Exit if no log file argument is present
if ($logfile eq "")
{
  print "\n";
  print "**Error: missing log file name argument\n";
  exit;
}

#--- If log file has '%' pattern, then fill in date info
if ($logfile =~ /\%/)
{
  open(COMM,"${main::SYSBIN}/date '+${logfile}'|");
  my $logfiledt=<COMM>; chop $logfiledt;
  close(COMM);
  $logfile = $logfiledt;
}

#--- Check that log file exists
if (!(-e "${logdir}/${logfile}"))
{
  print "\n";
  print "**Error in logcheck.pl program. Log file does not exist\n";
  print "  to archive: ${logdir}/${logfile}\n";
  print "  I quit!\n";
  exit;
}

my $TEMPFILE="/tmp/logdiff_$$";
my $TEMPFILE2="/tmp/logdiffb_$$";

#--- Create new empty old copy of log file if it doesn't exist yet
system "${main::SYSBIN}/touch ${logdir}/${logfile}.old";

#--- Compare and dump at most 100 lines to temporary file
system "${main::SYSBIN}/rm -f $TEMPFILE";
system "${main::SYSBIN2}/diff ${logdir}/${logfile}.old ${logdir}/${logfile}|tail -100>$TEMPFILE";

my @ignore=();
$ignore[0]='LOG:\s+unexpected EOF on client connection\s*$';
$ignore[1]='LOG:\s+could not receive data from client';

my $empty="yes";
my $skipline="yes";
my $buff;
my $ignore='';
my $ign;
open(INPUT,"<$TEMPFILE");
open(OUTPUT,">$TEMPFILE2");
while ($buff=<INPUT>)
{
  chop $buff;
  if ($skipline eq "yes")
  {
    $skipline="no";
    next;
  }
  #--- Ignore information lines
  $ignore="no";
  foreach $ign (@ignore)
  {
    if ($buff=~/$ign/)
    {
      $ignore="yes";
      last;
    }
  }
  if ($ignore eq "yes") {next;}
  $empty="no";
  print OUTPUT $buff,"\n";
}
close(INPUT);
close(OUTPUT);
system "${main::SYSBIN}/rm -f $TEMPFILE";

my $subject='';
if ($empty eq "no")
{
  $subject="${main::SERVERNAME} Postgres - new message(s) in ${logdir}/${logfile}";

  open(INPUT,"<$TEMPFILE2");
  #--- This opens e-mail via unit MESSAGE
  &emailopen($main::ADMINADDR,$main::ADMINISTRATOR,$subject);
  print MESSAGE "\n";
  while ($buff=<INPUT>)
  {
    chop $buff;
    print MESSAGE $buff,"\n";
  }
  close(INPUT);
  close(MESSAGE);
}

if ($skipline eq "no")
{
  system "${main::SYSBIN}/cp ${logdir}/${logfile} ${logdir}/${logfile}.old";
}
system "${main::SYSBIN}/rm -f $TEMPFILE2";
exit;


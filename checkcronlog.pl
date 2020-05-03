#!/usr/bin/perl
use strict;

#--- Set up libraries
my $fname=$0;
my $path="";
if ($fname =~ /^(.+\/)[^\/]+$/) { $path=$1; }

#--- Specify variables for this instance
require "${path}global.pl";

#--- Set up utilities library under main instance
require "${main::SCRIPT_MAIN}/utilities.pl";

#--- Exit if downtime is on
if (&downtimecheck()) {exit;}

#--- Get patterns to skip
my $skip=$ARGV[0];

my @skiplist=();
if ($skip ne '')
{
  @skiplist=split(/\s+/,$skip);
}

#--- Examine files in the cron log
my $subject="${main::SERVERNAME} ${main::ACCOUNT} cron jobs output";

my $chk=opendir(DIR,$main::CRON_LOG);
if ($chk != 1)
{
  #--- This opens e-mail via unit MESSAGE
  &emailopen($main::ADMINADDR,$main::SUPERADMINISTRATOR,$subject);
  print MESSAGE "\n";
  print MESSAGE "Could not access cron log: ${main::CRON_LOG}\n";
  close(MESSAGE);
}

#--- Get time as of 30 minutes ago
my $chktime=time - 1800;

#--- Want to check each file in the cronlog
my @filelist=readdir(DIR);
closedir(DIR);
@filelist=sort @filelist;

my $TEMPFILE="/var/tmp/checkcronlog_${main::ACCOUNT}_$$";
my $emailout="no";
my $ff;
my $ffstem;
my $file;
my $filebkup;
my $buff;
my $pattern;
my $skipit;
my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime, $blksize,$blocks)
;
open(OUTPUT,">$TEMPFILE");
#---
foreach $ff (@filelist)
{
  if ($ff =~ /^(.+)\.log$/)
  {
    $ffstem=$1;
    #--- If skiplist involved, check that file is not in the
    #--- skiplist
    if ($skip ne '')
    {
      $skipit='no';
      foreach $pattern (@skiplist)
      {
        if ($ffstem =~ /^${pattern}/)
        {
          $skipit='yes';
          last;
        }
      }
      if ($skipit eq 'yes')
      {
        next;
      }
    }

    $file="${main::CRON_LOG}/$ff";

    #--- Skip the file if it has an advisory lock on it
    open(CHECKWORK,"+<${file}");
    unless (flock(CHECKWORK, 2|4))
    {
      close(CHECKWORK);
      next;
    }
    close(CHECKWORK);

    #--- If file was last changed less than 30 minutes ago, then skip it
    ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,
     $blksize,$blocks) = stat($file);
#print "\n";
#print "FILE:$file\n";
#print " chktime:$chktime\n";
#print " mtime:$mtime\n";
    if ($mtime > $chktime) {next;}

    #--- If contents found, then copy to output and rename
    if ($size>0)
    {
      $emailout="yes";
      $filebkup="${main::CRON_LOG}/${ffstem}.bkuplog";
      open(INPUT,"<$file");
      open(BACKUP,">$filebkup");

      print OUTPUT "\n";
      print OUTPUT "="x65,"\n";
      print OUTPUT "== Cronjob log contents: $ff\n";
      print OUTPUT "="x65,"\n";
      print OUTPUT "\n";
      while($buff=<INPUT>)
      {
        print OUTPUT $buff;
        print BACKUP $buff;
      }
      close(INPUT);
      close(BACKUP);
      &setpermit($filebkup);
    }
    #--- Delete the file
    system "${main::SYSBIN}/rm -f ${file}";
  }
}
close(OUTPUT);

#--- E-mail?
if ($emailout eq "yes")
{
  #--- This opens e-mail via unit MESSAGE
  &emailopen($main::ADMINADDR,$main::SUPERADMINISTRATOR,$subject);

  open(INPUT,"<$TEMPFILE");
  while($buff=<INPUT>)
  {
    print MESSAGE $buff;
  }
  close(MESSAGE);
}

#---
system "${main::SYSBIN}/rm -f $TEMPFILE";

exit;


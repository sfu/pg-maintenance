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

#--- Get arguments
my $dir=$ARGV[0];
my $pattern=$ARGV[1];
my $numdays=$ARGV[2];
my $numhours=$ARGV[3];
my $emailflag=$ARGV[4];

#--- Direct any output to a log
&logout();

#--- Exit if no arguments
if ($dir eq "")
{
  print "\n";
  print "**Error: missing directory argument\n";
  exit;
}

my $subject="${main::SERVERNAME} ${main::ACCOUNT} delete old files";

opendir(DIR,$dir);
my @filenames=readdir(DIR);
closedir(DIR);

my $mintime=(86400*$numdays)+(3600*$numhours);

my @filelist=();
my $empty="yes";
my $ff;
my $file;
my $timediff;
my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks);

#--- Process each file name in the list
foreach $ff (@filenames)
{
  if ($ff eq '.' || $ff eq '..') {next;}
  if ($ff =~ /$pattern/)
  {
    $file="$dir/$ff";
    ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,
     $blksize,$blocks) = stat($file);
    if ($uid eq "") {next;}
    $timediff=time-$mtime;
    if ($timediff > $mintime)
    {
      system "${main::SYSBIN}/rm -f $file";
      #print "remove $file\n";
      push(@filelist,$file);
      $empty="no";
    }
  }
}

#--- Send message if any files got deleted
if ($empty eq "no" && $emailflag eq "fullemail")
{
  #--- This opens e-mail via unit MESSAGE
  &emailopen($main::ADMINADDR,$main::ADMINISTRATOR,$subject);

  print MESSAGE "\n";
  print MESSAGE "The following old files were deleted\n";
  print MESSAGE "------------------------------------\n";
  print MESSAGE "\n";
  foreach $file (@filelist)
  {
    print MESSAGE $file,"\n";
  }
  close(MESSAGE);
}

exit;


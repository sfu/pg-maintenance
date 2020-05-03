#!/usr/bin/perl
#---
#--- This is a simple script for deleting files from a
#--- particular directory matching a certain pattern of which
#--- x files are to be kept
#---
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
my $dir=$ARGV[0];
my $pattern=$ARGV[1];
my $numkeep=$ARGV[2];

#--- Exit if downtime is on
if (&downtimecheck()) {exit;}

#--- Direct any output to a log
&logout();

#--- Exit if no arguments
if ($numkeep eq "")
{
  print "\n";
  print "**Error: missing number of files to keep\n";
  exit;
}

opendir(DIR,$dir);
my @filenames = grep { /${pattern}/ } readdir(DIR);
closedir(DIR);

my $ff;
my $file;
my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,$blksize,$blocks);

#--- Get hash list of files with modification times
my %filelist=();
my $filelistnum=0;
foreach $ff (@filenames)
{
  $file="$dir/$ff";
  ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,$atime,$mtime,$ctime,
   $blksize,$blocks) = stat($file);
  if ($uid eq "") {next;}
  $mtime=sprintf("%015d",$mtime);
  $filelist{"${mtime}\0${ff}"}='x';
  $filelistnum++;
}

#--- Number of files to delete
my $filedelnum = $filelistnum - $numkeep;

my $ii;
my $knt=0;
foreach $ii (sort (keys %filelist))
{
  ($mtime,$ff)=split(/\0/,$ii);
  $file="$dir/$ff";
  $knt++;
  if ($knt <= $filedelnum)
  {
    system "${main::SYSBIN}/rm -f $file";
    #print "${main::SYSBIN}/rm -f $file","\n";
  }
  #else
  #{
  #  print "KEEP FILE:",$file,"\n";
  #}
}
exit;


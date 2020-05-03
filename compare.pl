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

#--- Arguments?
my $dirname=$ARGV[0];
my $dirname2=$ARGV[1];

#---
my $TEMPFILE="/var/tmp/compare_${main::ACCOUNT}_$$";

#--- Main directory
if ($dirname eq '')
{
  print "\nName of main directory to compare:";
  $dirname=<STDIN>;
  chop $dirname;
}

#--- Check that main directory exists (and get list of files)
my $chk=opendir(DIR,$dirname);
my @filenames=readdir(DIR);
closedir(DIR);
if ($chk != 1)
{
  print "No such main directory:",$dirname,"\n";
  exit;
}
@filenames=sort @filenames;

#--- Comparison directory
if ($dirname2 eq '')
{
  print "\nName of directory to compare with:";
  $dirname2=<STDIN>;
  chop $dirname2;
}

#--- Check that comparison directory exists
$chk=opendir(DIR,$dirname2);
closedir(DIR);
if ($chk != 1)
{
  print "No such comparison directory:",$dirname2,"\n";
  exit;
}

my $ff;
my $pause;
my $firstone="";
my $buff;
my $chk2;

foreach $ff (@filenames)
{
  if ($ff ne "." && $ff ne ".." && $ff !~ /\.old$/  && $ff !~ /\.bak$/)
  {
    $chk2=opendir(DIR,"${dirname}/$ff");
    closedir(DIR);
    if ($chk2 == 1) {next;}
    $chk=open(CHECK,"<$dirname2/$ff");
    close(CHECK);
    if ($chk == 1)
    {
      system "${main::SYSBIN}/rm -f $TEMPFILE";
      system "${main::SYSBIN2}/diff $dirname/$ff $dirname2/$ff>$TEMPFILE";
      open(INPUT,"<$TEMPFILE");
      $firstone="yes";
      while($buff=<INPUT>)
      {
        if ($firstone eq "yes")
        {
          print "\n";
          print "===================================================================\n";
          print "Difference found for file $dirname/$ff\n";
          print "                 and file $dirname2/$ff\n";
          print "===================================================================\n";
          print "Press ENTER to continue...";
          $pause=<STDIN>;
          $firstone="no";
        }
        print $buff;
      }
      close(INPUT);
      system "${main::SYSBIN}/rm -f $TEMPFILE";
    }
    else
    {
      print "===================================================================\n";
      print "\n***File $dirname2/$ff does not exist\n";
      print "===================================================================\n";
      print "Press ENTER to continue...";
      $pause=<STDIN>;
    }
  }
}

exit;

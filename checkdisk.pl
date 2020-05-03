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
my $dir=$ARGV[0];
my $minspace=$ARGV[1];

#--- Exit if no arguments
if ($dir eq "")
{
  print "\n";
  print "**Error: missing directory argument\n";
  exit;
}

#--- Direct any output to a log
&logout();

#--- Check that there is enough available space in the main archive directory
#--- Minimum disk space wanted (in K bytes)
my $availspace=&checkspace($dir);
my $subject;
$subject="${main::SERVERNAME} Postgres - Disk space problem";
if ($availspace < 0)
{
  #--- This opens e-mail via unit MESSAGE
  &emailopen($main::ADMINADDR,$main::ADMINISTRATOR,$subject);
  print MESSAGE "\n";
  print MESSAGE "Unable to use df command to get available diskspace for ${dir}\n";
  print MESSAGE "\n";
  close(MESSAGE);
  exit;
}
elsif ($availspace < $minspace)
{
  #--- This opens e-mail via unit MESSAGE
  &emailopen($main::ADMINADDR,$main::ADMINISTRATOR,$subject);

  print MESSAGE "\n";
  print MESSAGE "Diskspace available for ${dir}\n";
  print MESSAGE "Found:   $availspace K bytes\n";
  print MESSAGE "Minimum: $minspace K bytes\n";
  print MESSAGE "\n";
  close(MESSAGE);
  exit;
}

exit;

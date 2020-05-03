#!/usr/bin/perl
use strict;

#---
#--- Commands to get basic name of the machine in upper case
$main::SYSBIN='/bin';
$main::SERVERNAME=`${main::SYSBIN}/hostname`;
$main::SERVERNAME=uc($main::SERVERNAME);
$main::SERVERNAME=~s/\n//g;

#--- Get this account
$main::ACCOUNT=getpwuid($<);

#--- Set other useful variables
$main::ADMINADDR='iti-dbsupport@sfu.ca';
$main::ADMINISTRATOR='wolfgang@sfu.ca';

#---
my $subject="==CHECK TO SEE THAT EMAIL IS WORKING== ${main::SERVERNAME}/${main::ACCOUNT}";
&emailopen($main::ADMINADDR,$main::ADMINISTRATOR,$subject);

print MESSAGE "\n";
print MESSAGE $subject,"\n";
close(MESSAGE);

exit;

#-------------------------------------------------------------------
#--- Procedure to send a message
#-------------------------------------------------------------------
sub emailopen
{
  my ($sender,$sendto,$subject) = @_;
  open (MESSAGE, "|/bin/mailx -s '${subject}' -r ${sender} ${sendto}");
}

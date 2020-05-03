use strict;
#----------------
sub emailopen
{
  my ($sender,$sendto,$subject) = @_;
  open (MESSAGE, "|/bin/mailx -s '${subject}' -r ${sender} ${sendto}");
}

#----------------
sub trim
{
  my ($val)=@_;
  if ($val =~ /^\s*$/) {return '';}
  if ($val =~ /^(.*[^\s])\s+$/)
  {
    $val=$1;
  }
  if ($val =~ /^\s+([^\s].*)$/)
  {
    $val=$1;
  }
  return $val;
}

#----------------
sub rtrim
{
  my ($val)=@_;
  if ($val =~ /^\s*$/) {return '';}
  if ($val =~ /^(.*[^\s])\s+$/)
  {
    $val=$1;
  }
  return $val;
}

#----------------
sub ltrim
{
  my ($val)=@_;
  if ($val =~ /^\s+([^\s].*)$/)
  {
    $val=$1;
  }
  return $val;
}

#--- Check available space left for a particular directory
sub checkspace
{
  my ($dir) = @_;

  my $TEMPFILE="${main::SCRIPT_TEMP}/checkspace_$$.txt";

  #--- Get amount of space left for $dir
  system "${main::SYSBIN}/df -k ${dir} > $TEMPFILE";

  #--- Read lines of output into variables
  open(INWORK,"<$TEMPFILE");
  my $heading=<INWORK>;
  chop $heading;
  my $info=<INWORK>;
  chop $info;
  #--- If no blank in the line, then read next line and append
  #--- to the info line
  my $info2;
  if ($info !~ /\s/)
  {
    $info2=<INWORK>;
    chop $info2;
    $info = $info.' '.$info2;
  }
  close(INWORK);

  #--- Don't need temp file anymore, so delete it
  system "${main::SYSBIN}/rm -f $TEMPFILE";

  #--- Parse result of df command
  #Filesystem           1K-blocks      Used Available Use% Mounted on
  if ($heading !~ /^\s*Filesystem\s+1K\-blocks\s+Used\s+Available\s/)
  {
    return -1;
  }

  #/dev/dsk/c0t1d0s7    32956052 21235651 11390841    66%    /data
  #/dev/mapper/rootvg-lv02
  elsif ($info =~ /^\s*([^\s]+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\%\s/)
  {
    my $filesystem=$1;
    my $kbytes=$2;
    my $used=$3;
    my $avail=$4;
    my $capacity=$5;
    return $avail;
  }
  return -1;
}

#--- If directory does not exist, then create it
#--- Return 1 if creation fails
sub createdir
{
  my ($dir, $interactflag, $permit) = @_;

  #--- Check that directory exists
  my $answer='';
  my $chk=opendir(DIR,$dir);
  closedir(DIR);
  if ($chk != 1)
  {
    if ($interactflag ne 'noninteractive')
    {
      print "\n";
      print "**Warning: directory $dir does not exist.\n";
      print "  Is it alright to create it and continue?\n";
      print "  Press ENTER to create, N to not create, or Q to quit:";
      $answer=<STDIN>;
      chop $answer;
      if ($answer =~ /^\s*[qQ]\s*$/)
      {
        return 1;
      }
    }
    #--- Create the directory?
    if ($answer eq '')
    {
      system "${main::SYSBIN}/mkdir $dir";
      &setpermit($dir,$permit);
      #--- Check that creation succeeded
      $chk=opendir(DIR,$dir);
      closedir(DIR);
      if ($chk != 1)
      {
        print "\n";
        print "**Error: unable to create directory $dir\n";
        return 1;
      }
    }
  }
  return 0;
}

#--- File viewer
sub view
{
  my ($outfile, $displayline) = @_;

  if ($displayline eq "")
  {
    $displayline="Press ENTER to view output, type N otherwise:";
  }

  print "\n";
  print $displayline;
  my $answer=<STDIN>;
  chop $answer;
  if ($answer !~ /^\s*[nN]\s*$/)
  {
    system "${main::SYSBIN}/more $outfile";
  }
  return;
}

#--- File name constructor
sub genfilename
{
  my ($dir, $stemname, $suffix) = @_;

  #--- Get list of files in current directory
  my $chk=opendir(DIR,$dir);
  my @filenames=readdir(DIR);
  closedir(DIR);

  my $ff;
  my $maxnum=0;
  my $num;
  foreach $ff (@filenames)
  {
    if ($ff =~ /^${stemname}(\d{4})\.${suffix}$/)
    {
      $num=$1;
      if ($num > $maxnum) {$maxnum=$num;}
    }
  }

  #--- If maximum number has been reached, then we need to look for
  #--- next available file with lowest number
  my $scriptfile='';
  my $chk;
  if ($maxnum >= 9999)
  {
    $maxnum=0;
    while ($maxnum < 9999)
    {
      $scriptfile=sprintf("%-s%04d.%-s",$stemname,$maxnum+1,$suffix);
      $chk=open(CHECK,"${dir}/${scriptfile}");
      close(CHECK);
      #--- Exit the loop as soon as filename found that does not exist
      if ($chk != 1) {last;}
      $maxnum++;
    }
  }
  #--- Otherwise the next available number should work
  else
  {
    $scriptfile=sprintf("%-s%04d.%-s",$stemname,$maxnum+1,$suffix);
    $chk=open(CHECK,"${dir}/${scriptfile}");
    close(CHECK);
    if ($chk == 1) {$scriptfile='';}
  }
  return $scriptfile;

}

#--- Ask a question. Accept answer if validity check passes
sub ask
{
  my ($question, $default, $validitychk, $validitymsg, $quitoption) = @_;

  my $answer='';
  while (1)
  {
    print "\n";
    print $question;
    $answer=<STDIN>;
    chop $answer;
    $answer=&trim($answer);
    #--- Exit with nothing if null answer option specified
    if ($answer eq '' && $quitoption ne '') {return '';}
    #--- Check for default if appropriate
    if ($default ne '' && $answer eq '') {return $default;}
    #--- Do validity check if appropriate
    if ($validitychk ne '')
    {
      if ($answer =~ /${validitychk}/)
      {
        return $answer;
      }
      else
      {
        print "\n";
        print "**Error: Invalid answer\n";
        print "         ",$validitymsg,"\n";
        print "         Please try again\n";
      }
    }
    else
    {
      return $answer;
    }
  }
}

#--- Check if directory has any objects
sub checkdir
{
  my ($dir) = @_;

  my $chk=opendir(DIR,$dir);
  my @filelist=readdir(DIR);
  closedir(DIR);

  my $ff;
  my $found='no';
  foreach $ff (@filelist)
  {
    if ($ff eq '.' || $ff eq '..') {next;}
    $found='yes';
    last;
  }

  if ($found eq 'yes') {return 1;}
  return 0;
}

#--- Execute command to set permission
sub setpermit
{
  my ($item, $permit) = @_;

  if ($permit ne "")
  {
    system "${main::SYSBIN}/chmod ${permit} ${item}";
  }
  else
  {
    system "${main::SYSBIN}/chmod ${main::NOPERMIT} ${item}";
  }
  return 0;
}

#--- Return error if file does not exist
sub notfileexist
{
  my ($file) = @_;
  my $chk=open(CHECKEXIST,"<$file");
  close(CHECKEXIST);
  if ($chk == 1)
  {
    return 0;
  }
  else
  {
    print "\n";
    print "**Error: file ${file} does not exist\n";
    return 1;
  }
}

#--- Return error if file does exist
sub fileexist
{
  my ($file) = @_;
  my $chk=open(CHECKEXIST,"<$file");
  close(CHECKEXIST);
  if ($chk == 1)
  {
    print "\n";
    print "**Error: file ${file} exists\n";
    return 1;
  }
  else
  {
    return 0;
  }
}

#--- Direct standard and error output to an output file
sub logout
{
  my ($permit, $logdir, $logfile) = @_;

  #--- If logdir not specified, then set default
  if ($logdir eq '')
  {
    $logdir=$main::CRON_LOG;
  }

  #--- If logfile not specified, generate a base name
  if ($logfile eq '')
  {
    $logfile=$0;
    if ($logfile =~ /\/([^\/]+)$/)
    {
      $logfile=$1;
    }
    if ($logfile =~ /^(.+)\.pl$/)
    {
      $logfile=$1;
    }
  }

  $logfile = "${logdir}/${logfile}_$$.log";

  close(STDOUT);
  close(STDERR);
  open(STDOUT,">>${logfile}");
  open(STDERR,">>${logfile}");
  #--- Put an exclusive advisory lock on the two output units
  #flock(STDOUT,2);
  #flock(STDERR,2);
  #---
  &setpermit($logfile,$permit);

  $main::LOGOUT='yes';

  return 0;
}

#--- Get list of files in a directory
sub getfilelist
{
  my ($dir) = @_;

  #---
  my $chk=opendir(DIR,$dir);
  my @filelist=readdir(DIR);
  closedir(DIR);
  if ($chk != 1)
  {
    return (1,@filelist);
  }
  else
  {
    return (0,@filelist);
  }
}

#--- Check downtime schedule to see if we are within
sub downtimecheck
{
  my ($db) = @_;

  my @items=();
  my @weekdayfrom=();
  my @hourfrom=();
  my @hourto=();

  my $buff;
  my $dbcheck;
  my $progname;
  my $datedisplay;

  #--- If special "cron_no" file exists, then don't run
  if (-e "${main::SCRIPT_MAIN}/cron_no")
  {
    return 1;
  }

  open(INWORK,"<${main::SCRIPT_CONF}/downtime.conf");
  while($buff=<INWORK>)
  {
    chop $buff;
    #--- Skip blank lines and comment lines
    if ($buff =~ /^\s*$/) {next;}
    if ($buff =~ /^\s*\-\-/) {next;}

    #--- Check if cron unconditionally disabled for this job
    #--- based on database involved
    if ($buff =~ /^\s*cronoff\s+([^\s]+)\s*$/)
    {
      $dbcheck=$1;

      if ($dbcheck eq 'all')
      {
        close(INWORK);
        return 1;
      }

      elsif ($db ne '' && $dbcheck eq $db)
      {
        close(INWORK);

        #if ($main::LOGOUT ne 'yes')
        #{
        #  &logout();
        #}
        #$progname=$0;
        #if ($progname =~ /\/([^\/]+)$/)
        #{
        #  $progname=$1;
        #}
        #open(COMM,"${main::SYSBIN}/date '+%b %e, %Y %H:%M:%S'|");
        #$datedisplay=<COMM>; chop $datedisplay;
        #close(COMM);
        #print "\n";
        #print "** Cron job did not run **\n";
        #print "   Date and time: ",$datedisplay,"\n";
        #print "   Program name:  ",$progname,"\n";
        #print "   Specification: ",$buff,"\n";
        #print "\n";
        #print "   See spec details in ${main::SCRIPT_CONF}/downtime.conf\n";
        return 1;
      }
    }

    #--- Otherwise check for cron disabled for specific time period
    else
    {
      @items = split(/\s+/,$buff,4);
      push(@weekdayfrom,uc($items[0]));
      push(@hourfrom,$items[1]);
      push(@hourto,$items[3]);
    }
  }
  close(INWORK);

  #--- return if no date specific items found
  if ($#weekdayfrom < 0) {return 0;}

  #--- Get current day of week and time of day
  open(COMM,"${main::SYSBIN}/date '+%a %H:%M'|");
  my $timestamp=<COMM>; chop $timestamp;
  close(COMM);
  my ($weekday,$time)=split(/\s+/,uc($timestamp),2);
  my ($hour,$min)=split(":",$time,2);
  $min=($hour * 60) + $min;

  #---
  my $knt=0;
  my ($hhfrom,$mmfrom,$hhto,$mmto);
  while ($knt <= $#weekdayfrom)
  {
    if ($weekdayfrom[$knt] eq $weekday)
    {
      ($hhfrom,$mmfrom)=split(":",$hourfrom[$knt],2);
      ($hhto,$mmto)=split(":",$hourto[$knt],2);
      $mmfrom=($hhfrom * 60) + $mmfrom;
      $mmto=($hhto * 60) + $mmto;
      if ($mmfrom <= $min && $mmto > $min)
      {
        close(INWORK);

        #if ($main::LOGOUT ne 'yes')
        #{
        #  &logout();
        #}
        #$progname=$0;
        #if ($progname =~ /\/([^\/]+)$/)
        #{
        #  $progname=$1;
        #}
        #open(COMM,"${main::SYSBIN}/date '+%b %e, %Y %H:%M:%S'|");
        #$datedisplay=<COMM>; chop $datedisplay;
        #close(COMM);
        #print "\n";
        #print "** Cron job did not run **\n";
        #print "   Date and time: ",$datedisplay,"\n";
        #print "   Program name:  ",$progname,"\n";
        #print '   Specification: cronoff for ',$weekdayfrom[$knt],' ',$hourfrom[$knt],' to ',$hourto[$knt],"\n";
        #print "\n";
        #print "   See spec details in ${main::SCRIPT_CONF}/downtime.conf\n";
        return 1;
      }
    }
    $knt++;
  }
  return 0;
}

#--- Get list of files in a directory
sub getfilelist
{
  my ($dir) = @_;

  #---
  my $chk=opendir(WORKDIR,$dir);
  my @filelist=readdir(WORKDIR);
  closedir(WORKDIR);
  if ($chk != 1)
  {
    return (1,@filelist);
  }
  else
  {
    return (0,@filelist);
  }
}

#--- Display list of items and prompt user for a choice and return it
sub getitem
{
  my ($displayline, $allchoice, $listin) = @_;

  if ($displayline eq "")
  {
    $displayline="List of choices\n";
  }

  my @list=();
  if ($#$listin >= 0)
  {
    @list=@$listin;
  }

  #--- Return null if we get a null list
  if ($#list < 0)
  {
    return '';
  }

  #---
  my $knt;
  my $item;
  my $choice;
  while (1)
  {
    $knt=0;
    print "\n";
    print $displayline,"\n";
    print "\n";
    foreach $item (@list)
    {
      $knt++;
      printf "%3d) %-s\n",$knt,$item;
    }
    print "\n";
    if ($allchoice eq 'none')
    {
      print "Type number of choice:";
    }
    elsif ($allchoice ne "")
    {
      print "Type number of choice, or press ENTER for all of them:";
    }
    else
    {
      print "Type number of choice:";
    }
    $choice=<STDIN>;
    chop $choice;
    if ($allchoice eq 'none' && $choice =~ /^\s*$/)
    {
      $choice='';
      return $choice;
    }
    elsif ($allchoice ne "" && $choice =~ /^\s*$/)
    {
      $choice=join("\0",@list);
      return $choice;
    }
    elsif ($choice>0 && $list[$choice-1] ne "")
    {
      $choice=$list[$choice-1];
      return $choice;
    }
    else
    {
      print "\n";
      print "**Error: invalid choice. Try again.\n";
    }
  }
}

sub lockprog
{
  my ($lockdir, $lockfile) = @_;

  #--- Get the basic name of the program
  my $progname=$0;
  if ($progname =~ /\/([^\/]+)$/)
  {
    $progname=$1;
  }

  #--- If the lockdir is not specified, then set default
  if ($lockdir eq '')
  {
    $lockdir=$main::SCRIPT_LOG
  }

  #--- If the lockfile is not specified, generate from program name
  if ($lockfile eq '')
  {
    $lockfile=$progname;
    if ($lockfile =~ /^(.+)\.pl$/)
    {
      $lockfile=$1;
    }
  }

  #---
  $lockfile = "${lockdir}/${lockfile}.lock";

  #--- If file exists, then exit as it means this program is running
  #--- elsewhere
  if (-e "${lockfile}")
  {
    print "\n";
    print "** Error: ${progname} job is already running. I quit.\n";
    print "\n";
    exit;
  }

  #--- Otherwise create the lock file
  else
  {
    system "${main::SYSBIN}/touch ${lockfile}";
  }

  return;
}

sub unlockprog
{
  my ($lockdir, $lockfile) = @_;

  #--- Get the basic name of the program
  my $progname=$0;
  if ($progname =~ /\/([^\/]+)$/)
  {
    $progname=$1;
  }

  #--- If the lockdir is not specified, then set default
  if ($lockdir eq '')
  {
    $lockdir=$main::SCRIPT_LOG
  }

  #--- If the lockfile is not specified, generate from program name
  if ($lockfile eq '')
  {
    $lockfile=$progname;
    if ($lockfile =~ /^(.+)\.pl$/)
    {
      $lockfile=$1;
    }
  }

  #---
  $lockfile = "${lockdir}/${lockfile}.lock";

  #--- Remove lock file if it exists
  system "${main::SYSBIN}/rm -f ${lockfile}";

  return;
}

1;

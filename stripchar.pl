#!/usr/bin/perl
while ($buff=<STDIN>)
{
  chop $buff;
  chop $buff;
  print $buff,"\n";
}
exit;

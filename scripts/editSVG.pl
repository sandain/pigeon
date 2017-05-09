#!/usr/bin/perl

use strict;
use warnings;

my $usage = "Usage: $0 <Input File> <Output File> <X Offset> <Y Offset>\n";

my ($inputFile, $outputFile, $xOffset, $yOffset) = @ARGV;

die $usage unless (@ARGV >= 2);
die $usage unless (-e $inputFile);


open INPUT, '<' . $inputFile or die "Error: unable to open file: $!\n";
open OUTPUT, '>' . $outputFile or die "Error: unable to write to file: $!\n";
while (my $line = <INPUT>) {
  $line =~ s/[\r\n]//g;

  if ($line =~ /(.*)rotate\(-90\s+([\d.]+),([\d.]+)\)(.*)/) {
    my $x = $2 + $xOffset;
    my $y = $3 + $yOffset;
    $line = "$1rotate(-90 $x,$y)$4";
  }
  if ($line =~ /(.*)translate\(([\d.]+),([\d.]+)\)\s+rotate\(-90\)\s+translate\(-[\d.]+,-[\d.]+\)(.*)/) {
    my $x = $2 + $xOffset;
    my $y = $3 + $yOffset;
    $line = "$1rotate(-90 $x,$y)$4";
  }
  if ($line =~ /(.*)<text\s+x="([\d.]+)"\s+y="([\d.]+)"(.*)/) {
    my $x = $2 + $xOffset;
    my $y = $3 + $yOffset;
    print OUTPUT "$1<text x=\"$x\" y=\"$y\"$4\n";
  }
  elsif ($line =~ /(.*)<tspan\s+(.*)x=\"([\d.]+)\"\s+y=\"([\d.]+)\"(.*)/) {
    my $x = $3 + $xOffset;
    my $y = $4 + $yOffset;
    print OUTPUT "$1<tspan $2x=\"$x\" y=\"$y\"$5\n";
  }
  elsif ($line =~ /(.*)<line\s+x1="([\d.]+)"\s+y1="([\d.]+)"\s+x2="([\d.]+)"\s+y2="([\d.]+)"(.*)/) {
    my $x1 = $2 + $xOffset;
    my $y1 = $3 + $yOffset;
    my $x2 = $4 + $xOffset;
    my $y2 = $5 + $yOffset;
    print OUTPUT "$1<line x1=\"$x1\" y1=\"$y1\" x2=\"$x2\" y2=\"$y2\"$6\n";
  }
  elsif ($line =~ /(.*)<path\s+(.*)d=\"([\w\s\.\,\-]+)\"(.*)\/>/) {
    my $path = "";
    foreach my $cmd (split /\s+/, $3) {
      if ($cmd =~ /[Z]/i) {
        $path .= $cmd;
      }
      elsif ($cmd =~ /([\d.]+),([\d.]+)/) {
        my $x = $1 + $xOffset;
        my $y = $2 + $yOffset;
        $path .= $x . ',' . $y . ' ';
      }
      else {
        $path .= $cmd . ' ';
      }
    }
    print OUTPUT "$1<path $2d=\"$path\"$4\/>\n";
  }
  elsif ($line =~ /(.*)<rect\s+(.*)x=\"([\d.]+)\"\s+y=\"([\d.]+)\"\s+width=\"([\d.]+)\"\s+height=\"([\d.]+)\"(.*)/) {
    my $x1 = $3 + $xOffset;
    my $y1 = $4 + $yOffset;
    my $x2 = $x1 + $5;
    my $y2 = $y1 + $6;
    my $path = "M $x1,$y1 L $x2,$y1 $x2,$y2 $x1,$y2 Z";
    print OUTPUT "$1<path $2d=\"$path\"$7\n";
  }
  else {
    print OUTPUT "$line\n";
  }
}
close INPUT;
close OUTPUT;

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

  if ($line =~ /(.*)translate\((\d+),(\d+)\) rotate\(-90\) translate\(-\d+,-\d+\)(.*)/) {
    my $x = $2 + $xOffset;
    my $y = $3 + $yOffset;
    $line = "$1rotate(-90 $x,$y)$4";
  }

  if ($line =~ /<text\s+x="(\d+)"\s+y="(\d+)"(.*)/) {
    my $x = $1 + $xOffset;
    my $y = $2 + $yOffset;
    print OUTPUT "  <text x=\"$x\" y=\"$y\"$3\n";
  }
  elsif ($line =~ /(.*)<tspan\s+(.*)x=\"(\d+)\"\s+y=\"(\d+)\"(.*)/) {
    my $x = $3 + $xOffset;
    my $y = $4 + $yOffset;
    print OUTPUT "$1<tspan $2x=\"$x\" y=\"$y\"$5\n";
  }
  elsif ($line =~ /<line\s+x1="(\d+)"\s+y1="(\d+)"\s+x2="(\d+)"\s+y2="(\d+)"(.*)/) {
    my $x1 = $1 + $xOffset;
    my $y1 = $2 + $yOffset;
    my $x2 = $3 + $xOffset;
    my $y2 = $4 + $yOffset;
    print OUTPUT "  <line x1=\"$x1\" y1=\"$y1\" x2=\"$x2\" y2=\"$y2\"$5\n";
  }
  elsif ($line =~ /<path\s+(.*)d=\"(.*)\"(.*)\/>/) {
    my $path = "";
    foreach my $cmd (split /\s+/, $2) {
      if ($cmd =~ /[ML]/) {
        $path .= $cmd . ' ';
      }
      elsif ($cmd =~ /[Z]/) {
        $path .= $cmd;
      }
      elsif ($cmd =~ /(\d+),(\d+)/) {
        my $x = $1 + $xOffset;
        my $y = $2 + $yOffset;
        $path .= $x . ',' . $y . ' ';
      }
    }
    print OUTPUT "  <path $1d=\"$path\"$3\/>\n";
  }
  else {
    print OUTPUT "$line\n";
  }
}
close INPUT;
close OUTPUT;

#!/usr/bin/perl

use strict;
use warnings;

my $usage = "Usage: $0 <Input File> <Output File> <X Offset> <Y Offset> <X Scale> <Y Scale>\n";

my ($inputFile, $outputFile, $xOffset, $yOffset, $xScale, $yScale) = @ARGV;

die $usage unless (@ARGV >= 2);
die $usage unless (-e $inputFile);

$xOffset = 0 if (not defined $xOffset);
$yOffset = 0 if (not defined $yOffset);
$xScale = 1 if (not defined $xScale);
$yScale = 1 if (not defined $yScale);

my $input;
{
  local $/ = undef;
  open INPUT, '<' . $inputFile or die "Error: unable to open file: $!\n";
  binmode INPUT;
  $input = <INPUT>;
  close INPUT;
}

# Remove excess line returns from input.
$input =~ s/[\r]//g;
$input =~ s/([\"\w]+)\n\s*(\w+)/$1 $2/g;

open OUTPUT, '>' . $outputFile or die "Error: unable to write to file: $!\n";
foreach my $line (split /\n/, $input) {

  # Add missing commas.
  $line =~ s/\s+(\-?\d+\.?\d*)\s+(\-?\d+\.?\d*)/ $1,$2/g;
  # Translate rgb colors to hex colors.
  if ($line =~ /(.*)rgb\(([\d\.\%]+),([\d\.\%]+),([\d\.\%]+)\)(.*)/) {
    my $before = $1;
    my $r = $2;
    my $g = $3;
    my $b = $4;
    my $after = $5;
    # Check for percantages and convert to an int.
    if ($r =~ /([\d\.]+)\%/) { $r = int ($1 / 100 * 255 + 0.5); }
    if ($g =~ /([\d\.]+)\%/) { $g = int ($1 / 100 * 255 + 0.5); }
    if ($b =~ /([\d\.]+)\%/) { $b = int ($1 / 100 * 255 + 0.5); }
    # Convert int to hex.
    $r = sprintf "%02x", $r;
    $g = sprintf "%02x", $g;
    $b = sprintf "%02x", $b;
    # Create line with translated hex colors.
    $line = $before . '#' . $r . $g . $b . $after;
  }
  # Simplify rotate.
  if ($line =~ /(.*)rotate\(-90\s+([\d\.]+),([\d\.]+)\)(.*)/) {
    my $x = $2 * $xScale + $xOffset;
    my $y = $3 * $yScale + $yOffset;
    $line = "$1rotate(-90 $x,$y)$4";
  }
  if ($line =~ /(.*)translate\(([\d\.]+),([\d\.]+)\)\s+rotate\(-90\)\s+translate\(-[\d\.]+,-[\d\.]+\)(.*)/) {
    my $x = $2 * $xScale + $xOffset;
    my $y = $3 * $yScale + $yOffset;
    $line = "$1rotate(-90 $x,$y)$4";
  }
  # Capture text elements.
  if ($line =~ /(.*)<text\s+x="([\d\.]+)"\s+y="([\d\.]+)"(.*)/) {
    my $x = $2 * $xScale + $xOffset;
    my $y = $3 * $yScale + $yOffset;
    print OUTPUT "$1<text x=\"$x\" y=\"$y\"$4\n";
  }
  # Capture tspan elements.
  elsif ($line =~ /(.*)<tspan\s*(.*\s+)x=\"([\d\.]+)\"\s+y=\"([\d\.]+)\"(.*)/) {
    my $x = $3 * $xScale + $xOffset;
    my $y = $4 * $yScale + $yOffset;
    print OUTPUT "$1<tspan $2x=\"$x\" y=\"$y\"$5\n";
  }
  # Capture line elements.
  elsif ($line =~ /(.*)<line\s+x1="([\d\.]+)"\s+y1="([\d\.]+)"\s+x2="([\d\.]+)"\s+y2="([\d\.]+)"(.*)/) {
    my $x1 = $2 * $xScale + $xOffset;
    my $y1 = $3 * $yScale + $yOffset;
    my $x2 = $4 * $xScale + $xOffset;
    my $y2 = $5 * $yScale + $yOffset;
    print OUTPUT "$1<line x1=\"$x1\" y1=\"$y1\" x2=\"$x2\" y2=\"$y2\"$6\n";
  }
  # Capture path elements.
  elsif ($line =~ /(.*)<path\s+(.*\s*)d=\"([\w\s\.\,\-]+)\"(.*)\/>/) {
    my @path;
    my $relative = 0;
    foreach my $cmd (split /\s+/, $3) {
      $relative = 1 if ($cmd =~ /[mlc]/);
      $relative = 0 if ($cmd =~ /[MLC]/);
      if ($cmd =~ /([\d\.\-]+),([\d\.\-]+)/ && ! $relative) {
        my $x = $1 * $xScale + $xOffset;
        my $y = $2 * $yScale + $yOffset;
        push @path, $x . ',' . $y;
      }
      else {
        push @path, $cmd;
      }
    }
    printf OUTPUT "%s<path %sd=\"%s\"%s\/>\n", $1, $2, join (' ', @path), $4;
  }
  # Capture rect elements.
  elsif ($line =~ /(.*)<rect\s*(.*\s+)x=\"([\d\.]+)\"\s+y=\"([\d\.]+)\"\s+width=\"([\d\.]+)\"\s+height=\"([\d\.]+)\"(.*)/) {
    my $x1 = $3 * $xScale + $xOffset;
    my $y1 = $4 * $yScale + $yOffset;
    my $x2 = $x1 + $5;
    my $y2 = $y1 + $6;
    my $path = "M $x1,$y1 L $x2,$y1 $x2,$y2 $x1,$y2 Z";
    print OUTPUT "$1<path $2d=\"$path\"$7\n";
  }
  # Capture circle elements.
  elsif ($line =~ /(.*)<circle(.*\s+)cx="([\d\.]+)"\s+cy="([\d\.]+)"\s+r="([\d\.]+)"(.*)/) {
    my $x = $3 * $xScale + $xOffset;
    my $y = $4 * $yScale + $yOffset;
    print OUTPUT "$1<circle$2cx=\"$x\" cy=\"$y\" r=\"$5\"$6\n";
  }
  else {
    print OUTPUT "$line\n";
  }
}
close OUTPUT;

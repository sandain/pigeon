#!/usr/bin/perl

use 5.010;
use strict;
use warnings;
use experimental qw (switch);
use XML::LibXML;

my $usage = "Usage: $0 <Input File> <Output File> <X Offset> <Y Offset> <X Scale> <Y Scale>\n";

my %entities = (
  '<' => '&lt;',
  '>' => '&gt;',
  '&' => '&amp;',
  '"' => '&quot;',
  "'" => '&apos;'
);

my ($inputFile, $outputFile, $xOffset, $yOffset, $xScale, $yScale) = @ARGV;

die $usage unless (@ARGV >= 2);
die $usage unless (-e $inputFile);

$xOffset = 0 if (not defined $xOffset);
$yOffset = 0 if (not defined $yOffset);
$xScale = 1 if (not defined $xScale);
$yScale = 1 if (not defined $yScale);


sub color {
  my ($color) = @_;
  given ($color) {
    when (/rgb\(([\d\.\%]+),\s*([\d\.\%]+),\s*([\d\.\%]+)\)/) {
      my ($r, $g, $b) = ($1, $2, $3);
      # Check for percentages and convert to an int.
      if ($r =~ /([\d\.]+)\%/) { $r = int ($1 / 100 * 255 + 0.5); }
      if ($g =~ /([\d\.]+)\%/) { $g = int ($1 / 100 * 255 + 0.5); }
      if ($b =~ /([\d\.]+)\%/) { $b = int ($1 / 100 * 255 + 0.5); }
      # Return RGB values as translated hex colors.
      return sprintf "#%02x%02x%02x", $r, $g, $b ;
    }
    default { return $color; }
  }
}

sub transform {
  my ($transform) = @_;
  if ($transform =~ /translate\(([\d\.]+),([\d\.]+)\)\s+rotate\(-90\)\s+translate\(-[\d\.]+,-[\d\.]+\)/) {
    my $x = scale ($1, $xOffset, $xScale);
    my $y = scale ($2, $yOffset, $yScale);
    $transform = sprintf "rotate(-90 %s,%s)", $x, $y;
  }
  elsif ($transform =~ /rotate\(([-\d\.]+) ([-\d\.]+)[\s,]+([-\d\.]+)\)/) {
    my $x = scale ($2, $xOffset, $xScale);
    my $y = scale ($3, $yOffset, $yScale);
    $transform = sprintf "rotate(%s %s,%s)", $1, $x, $y;
  }
  elsif ($transform =~ /matrix\(([-\d\.]+)[\s,]+([-\d\.]+)[\s,]+([-\d\.]+)[\s,]+([-\d\.]+)[\s,]+([-\d\.]+)[\s,]+([-\d\.]+)\)/) {
    my $tx = scale ($5, $xOffset, $xScale);
    my $ty = scale ($6, $yOffset, $yScale);
    my $sx = ($1 > 0 ? 1 : -1) * sqrt ($1 ** 2 + $2 ** 2) * $xScale;
    my $sy = ($4 > 0 ? 1 : -1) * sqrt ($3 ** 2 + $4 ** 2) * $yScale;
    my $a = atan2 ($2, $3);
    $transform = '';
    $transform .= sprintf " translate(%s,%s)", $tx, $ty if ($tx != 0 && $ty != 0);
    $transform .= sprintf " scale(%s,%s)", $sx, $sy if ($sx != 1 && $sy != 1);
    $transform .= sprintf " rotate(%s %s,%s)", $a, $tx, $ty if ($a != 0);
  }
  return $transform;
}

sub path {
  my ($path) = @_;
  # Add missing spaces.
  $path =~ s/([mlcMLC])([\d-]+)/$1 $2/g;
  $path =~ s/(\d)-/$1 -/g;
  # Add missing commas.
  $path =~ s/\s+(\-?\d+\.?\d*)\s+(\-?\d+\.?\d*)/ $1,$2/g;
  my @path;
  my $relative = 0;
  foreach my $cmd (split /\s+/, $path) {
    $relative = 1 if ($cmd =~ /[mlc]/);
    $relative = 0 if ($cmd =~ /[MLC]/);
    if ($cmd =~ /([\d\.\-]+),([\d\.\-]+)/ && ! $relative) {
      my $x = scale ($1, $xOffset, $xScale);
      my $y = scale ($2, $yOffset, $yScale);
      push @path, $x . ',' . $y;
    }
    elsif ($cmd =~ /([\d\.\-]+),([\d\.\-]+)/ && $relative) {
      my $x = scale ($1, 0, $xScale);
      my $y = scale ($2, 0, $yScale);
      push @path, $x . ',' . $y;
    }
    else {
      push @path, $cmd;
    }
  }
  return join ' ', @path;
}

sub scale {
  my ($value, $offset, $scale) = @_;
  my $unit = '';
  if ($value =~ /([\d\.]+)([a-zA-Z\%]+)/) {
    $value = $1;
    $unit = $2;
  }
  $value = $value * $scale + $offset unless ($unit eq '%');
  return $value . $unit;
}

sub byOption {
  my $i = 0;
  my %order = map { $_ => $i++ } ('fill', 'stroke', 'x', 'y', 'x1', 'y1', 'x2', 'y2', 'cx', 'cy', 'r', 'd', 'version', 'baseProfile', 'width', 'height', 'viewBox');
  return $order{$a} <=> $order{$b} if (defined $order{$a} && defined $order{$b});
  return $order{$a} <=> 999 if (defined $order{$a});
  return 999 <=> $order{$b} if (defined $order{$b});
  return $a cmp $b;
}

sub options {
  my %options = map { $_->nodeName => $_->nodeValue } @_;
  my @opts;
  foreach my $option (sort byOption keys %options) {
    given ($option) {
      when ('baseProfile') {
       push @opts, "baseProfile=\"tiny\"";
      }
      when ('version') {
       push @opts, "version=\"1.2\"";
      }
      when ('d') {
       push @opts, sprintf "d=\"%s\"", path ($options{$option});
      }
      when ('fill') {
       push @opts, sprintf "fill=\"%s\"", color ($options{$option});
      }
      when ('stroke') {
       push @opts, sprintf "stroke=\"%s\"", color ($options{$option});
      }
      when ('transform') {
       push @opts, sprintf "transform=\"%s\"", transform ($options{$option});
      }
      when ('stroke-width') {
       push @opts, sprintf "stroke-width=\"%s\"", scale ($options{$option}, 0, $xScale);
      }
      when ('x') {
       push @opts, sprintf "x=\"%s\"", scale ($options{$option}, $xOffset, $xScale);
      }
      when ('y') {
       push @opts, sprintf "y=\"%s\"", scale ($options{$option}, $yOffset, $yScale);
      }
      when ('x1') {
       push @opts, sprintf "x1=\"%s\"", scale ($options{$option}, $xOffset, $xScale);
      }
      when ('y1') {
       push @opts, sprintf "y1=\"%s\"", scale ($options{$option}, $yOffset, $yScale);
      }
      when ('x2') {
       push @opts, sprintf "x2=\"%s\"", scale ($options{$option}, $xOffset, $xScale);
      }
      when ('y2') {
       push @opts, sprintf "y2=\"%s\"", scale ($options{$option}, $yOffset, $yScale);
      }
      when ('cx') {
       push @opts, sprintf "cx=\"%s\"", scale ($options{$option}, $xOffset, $xScale);
      }
      when ('cy') {
       push @opts, sprintf "cy=\"%s\"", scale ($options{$option}, $yOffset, $yScale);
      }
      when ('id') {}
      when ('class') {}
      when ('overflow') {}
      when ('enable-background') {}
      when ('xml:space') {}
      when (/inkscape/) {}
      when (/sodipodi/) {}
      default {
        push @opts, sprintf "%s=\"%s\"", $option, $options{$option};
      }
    }
  }
  return @opts > 0 ? ' ' . join (' ', @opts) : '';
}

sub outputNode {
  my ($node, $spacer) = @_;
  given ($node->nodeType) {
    when (XML_ELEMENT_NODE) { outputElementNode ($node, $spacer); }
    when (XML_TEXT_NODE)    { outputTextNode ($node); }
  }
}

sub outputElementNode {
  my ($node, $spacer) = @_;
  return unless ($node->nodeType == XML_ELEMENT_NODE);
  given ($node->nodeName) {
    when ('svg') {
      printf OUTPUT "%s<svg xmlns=\"http://www.w3.org/2000/svg\"%s>\n", " " x $spacer, options ($node->findnodes ('./@*'));
      foreach my $child ($node->childNodes) {
        outputNode ($child, $spacer + 2);
      }
      printf OUTPUT "%s</svg>\n", " " x $spacer;
    }
    when ('g') {
      printf OUTPUT "%s<g%s>\n", " " x $spacer, options ($node->findnodes ('./@*'));
      foreach my $child ($node->childNodes) {
        outputNode ($child, $spacer + 2);
      }
      printf OUTPUT "%s</g>\n", " " x $spacer;
    }
    when ('desc') {
      printf OUTPUT "%s<desc%s>", " " x $spacer, options ($node->findnodes ('./@*'));
      foreach my $child ($node->childNodes) {
        outputNode ($child, $spacer + 2);
      }
      print OUTPUT "</desc>\n";
    }
    when ('text') {
      printf OUTPUT "%s<text%s>", " " x $spacer, options ($node->findnodes ('./@*'));
      foreach my $child ($node->childNodes) {
        outputNode ($child, $spacer + 2);
      }
      print OUTPUT "</text>\n";
    }
    when ('tspan') {
      printf OUTPUT "<tspan%s>", options ($node->findnodes ('./@*'));
      foreach my $child ($node->childNodes) {
        outputNode ($child, $spacer + 2);
      }
      print OUTPUT "</tspan>";
    }
    default {
      print OUTPUT " " x $spacer;
      printf OUTPUT "<%s%s/>\n", $node->nodeName, options ($node->findnodes ('./@*'));
    }
  }
}

sub outputTextNode {
  my ($node) = @_;
  return unless ($node->nodeType == XML_TEXT_NODE);
  my $text = $node->data;
  return if ($text =~ /^\s+$/);
  # Swap entities with html codes to avoid malformed xml.
  foreach my $entity (keys %entities) {
    $text =~ s/$entity/$entities{$entity}/g;
  }
  print OUTPUT $text;
}

# Load the input file.
my $dom = XML::LibXML->load_xml (location => $inputFile);

# Register the SVG namespace.
my $xpc = XML::LibXML::XPathContext->new ($dom);
$xpc->registerNs ('svg', 'http://www.w3.org/2000/svg');

# Open the output file.
open OUTPUT, '>:encoding(UTF-8)', $outputFile or die "Error: unable to write to file: $!\n";

# Print the SVG data to the output file.
printf OUTPUT "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
outputNode ($xpc->findnodes ('/svg:svg'), 0);

# close the output file.
close OUTPUT;

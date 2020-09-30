#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use v5.10;

use File::Basename;

my $epsilon = 1e-6;

my $usage = "Usage: $0 <Species Matrix File> <Species Cutoff>\n";

my ($inputFile, $cutoff) = @ARGV;

die $usage unless (@ARGV > 0);
die $usage unless (-e $inputFile);

$cutoff = $epsilon unless (defined $cutoff);

my $name = basename ($inputFile, ".txt", ".csv");

my %data;
my @header = ();
open my $fh, '<' . $inputFile or die "Error: unable to open file: $!\n";
while (my $line = <$fh>) {
  $line =~ s/[\r\n]//g;
  my @cols = split /\t/, $line;
  my $id = shift @cols;
  $id =~ s/"//g;
  if (@header == 0) {
    @header = @cols;
    next;
  }
  next unless (eval (join '+', @cols) > 0);
  for (my $i = 0; $i < @cols; $i ++) {
    $data{$id}{$header[$i]} = $cols[$i];
  }
}
close $fh;

my %counts;
foreach my $species (keys %data) {
  foreach my $sample (@header) {
    $counts{sample}{$sample} += $data{$species}{$sample};
    $counts{species}{$species} += $data{$species}{$sample};
  }
}

printf "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
printf "<graphml xmlns=\"http://graphml.graphdrawing.org/xmlns\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://graphml.graphdrawing.org/xmlns http://graphml.graphdrawing.org/xmlns/1.0/graphml.xsd\">\n";
printf "<graph id=\"%s\" edgedefault=\"undirected\">\n", $name;

printf "<key id=\"type\" for=\"node\" attr.name=\"type\" attr.type=\"string\"/>\n";
printf "<key id=\"size\" for=\"node\" attr.name=\"size\" attr.type=\"double\"/>\n";
printf "<key id=\"weight\" for=\"edge\" attr.name=\"weight\" attr.type=\"double\"/>\n";

foreach my $sample (@header) {
  printf "<node id=\"%s\"><data key=\"type\">Sample</data><data key=\"size\">%e</data></node>\n", $sample, $counts{sample}{$sample};
}

foreach my $species (keys %data) {
  my $avg = $counts{species}{$species} / @header;
  next unless ($avg > $cutoff);
  printf "<node id=\"%s\"><data key=\"type\">Species</data><data key=\"size\">%e</data></node>\n", $species, $avg;
}

foreach my $species (keys %data) {
  my $avg = $counts{species}{$species} / @header;
  next unless ($avg > $cutoff);
  foreach my $sample (@header) {
    next unless ($data{$species}{$sample} > $epsilon);
    printf "<edge source=\"%s\" target=\"%s\"><data key=\"weight\">%e</data></edge>\n", $species, $sample, $data{$species}{$sample};
  }
}
printf "</graph>\n";
printf "</graphml>\n";

#!/usr/bin/perl

use strict;
use warnings;

use POSIX;

use Bio::SeqIO;

sub round {
  my $number = shift;
  return int ($number + .5 * ($number <=> 0));
}

my $usage = "Usage: $0 <sequence file> <cutoff>\n";

if (@ARGV == 0) {
  print $usage;
  exit;
}

my $file = $ARGV[0];
my $cutoff = $ARGV[1];

# Handle input files that are compressed with gzip.
if ($file =~ /\.t?gz/) {
  $file = "gunzip -c $file |";
}

# Handle input files that are compressed with bzip2.
if ($file =~ /\.t?bz2?/) {
  $file = "bunzip2 -c $file |";
}

if (not defined $cutoff) {
  $cutoff = 0;
}

my $format = "fasta";
$format = "fastq" if ($file =~ /fastq/);

my $seqIO = new Bio::SeqIO (-file => $file, -format => $format);

my %counter;
my $nucCounter = 0;

my @lengths;


while (my $seq = $seqIO->next_seq) {
  my $sequence = uc $seq->seq;
  my $length = length $sequence;
  next if ($length < $cutoff);
  push @lengths, $length;
  $nucCounter += $length;
  for (my $i = 0; $i < $length; $i ++) {
    my $char = substr $sequence, $i, 1;
    $counter{$char} ++;
  }
}

@lengths = sort { $a <=> $b } @lengths;

my $numSequences = scalar @lengths;
my $minLength = $lengths[0];
my $maxLength = $lengths[$#lengths];
my $medianLength;
if ($numSequences == 1) {
  $medianLength = $maxLength;
}
else {
  $medianLength = 0.5 * ($lengths[floor ($numSequences / 2)] + $lengths[ceil ($numSequences / 2)]);
}
my $meanLength = $nucCounter / $numSequences;


my ($n80, $n50, $n20);
my $totalLength = 0;
# n50 is a weighted median statistic such that 50% of the entire assembly is contained in
# contigs or scaffolds equal to or larger than this value
for (my $i = 0; $i < $numSequences; $i ++) {
  $totalLength += $lengths[$i];
  $n80 = $lengths[$i] if (not defined $n80 and $totalLength >= (1.0 - 0.8) * $nucCounter);
  $n50 = $lengths[$i] if (not defined $n50 and $totalLength >= (1.0 - 0.5) * $nucCounter);
  $n20 = $lengths[$i] if (not defined $n20 and $totalLength >= (1.0 - 0.2) * $nucCounter);
}

printf "File: %s\n", $file;
printf "No. sequences: %d\n", $numSequences;
printf "No. nucleotides: %d\n", $nucCounter;
printf "Min length: %d\n", $minLength;
printf "Max length: %d\n", $maxLength;
printf "Median length: %.1f\n", $medianLength;
printf "Mean length: %.1f\n", $meanLength;
printf "N80: %d\n", $n80;
printf "N50: %d\n", $n50;
printf "N20: %d\n", $n20;

foreach my $char (keys %counter) {
  my $charCounter = 0;
  $charCounter = ($counter{$char} / $nucCounter) if ($nucCounter > 0);
  printf "%s\t%d/%d\t%.3f\n", $char, $counter{$char}, $nucCounter, $charCounter;
}

#!/usr/bin/perl

use strict;
use warnings;

use POSIX;

use Bio::SeqIO;
use IO::Uncompress::Gunzip;
use IO::Uncompress::Bunzip2;
use FileHandle;
use Parallel::ForkManager;

sub round {
  my $number = shift;
  return int ($number + .5 * ($number <=> 0));
}

my $usage = "Usage: $0 <sequence file> <cutoff>\n";

die $usage unless (@ARGV >= 1);

my $file = $ARGV[0];
my $cutoff = $ARGV[1];

$cutoff = 0 if (not defined $cutoff);

# Handle sequence files that are compressed with gzip or bzip2.
my $fh;
if ($file =~ /\.t?gz/) {
  $fh = new IO::Uncompress::Gunzip ($file, -MultiStream => 1);
}
elsif ($file =~ /\.t?bz2/) {
  $fh = new IO::Uncompress::Bunzip2 ($file);
}
else {
  $fh = new FileHandle ($file);
}

# Attempt to detect the format of the sequence file.
my $format = "fasta";
$format = "fastq" if ($file =~ /fastq/);

my $seqIO = new Bio::SeqIO (
  -fh   => $fh,
  -format => $format
);

my %counter;
my $nucCounter = 0;

my @lengths;

my $pm = Parallel::ForkManager->new (16);

$pm->run_on_finish( sub {
  my ($pid, $exit_code, $ident, $exit_signal, $core_dump, $data) = @_;
  if ($data->{length} >= $cutoff) {
    push @lengths, $data->{length};
    $nucCounter += $data->{length};
    foreach my $char (keys %{$data->{chars}}) {
      $counter{$char} += $data->{chars}{$char};
    }
  }
});

while (my $seq = $seqIO->next_seq) {
  $pm->start and next;
  my $sequence = uc $seq->seq;
  my $length = length $sequence;
  my $chars;
  for (my $i = 0; $i < $length; $i ++) {
    my $char = substr $sequence, $i, 1;
    $chars->{$char} ++;
  }
  $pm->finish (0, { length => $length, chars => $chars });
}
$pm->wait_all_children;

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

my ($n90, $n80, $n50, $n20, $n10);
my $totalLength = 0;
# n50 is a weighted median statistic such that 50% of the entire assembly is contained in
# contigs or scaffolds equal to or larger than this value
for (my $i = 0; $i < $numSequences; $i ++) {
  $totalLength += $lengths[$i];
  $n90 = $lengths[$i] if (not defined $n90 and $totalLength >= (1.0 - 0.9) * $nucCounter);
  $n80 = $lengths[$i] if (not defined $n80 and $totalLength >= (1.0 - 0.8) * $nucCounter);
  $n50 = $lengths[$i] if (not defined $n50 and $totalLength >= (1.0 - 0.5) * $nucCounter);
  $n20 = $lengths[$i] if (not defined $n20 and $totalLength >= (1.0 - 0.2) * $nucCounter);
  $n10 = $lengths[$i] if (not defined $n10 and $totalLength >= (1.0 - 0.1) * $nucCounter);
}

printf "File: %s\n", $file;
printf "No. sequences: %d\n", $numSequences;
printf "No. nucleotides: %d\n", $nucCounter;
printf "Min length: %d\n", $minLength;
printf "Max length: %d\n", $maxLength;
printf "Median length: %.1f\n", $medianLength;
printf "Mean length: %.1f\n", $meanLength;
printf "N90: %d\n", $n90;
printf "N80: %d\n", $n80;
printf "N50: %d\n", $n50;
printf "N20: %d\n", $n20;
printf "N10: %d\n", $n10;
printf "G+C: %.2f%%\n", $nucCounter > 0 ? 100 * ($counter{'G'} + $counter{'C'}) / $nucCounter : 0;

foreach my $char (sort keys %counter) {
  my $charCounter = $nucCounter > 0 ? $counter{$char} / $nucCounter : 0;
  printf "%s\t%d/%d\t%.3f\n", $char, $counter{$char}, $nucCounter, $charCounter;
}

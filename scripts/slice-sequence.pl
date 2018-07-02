#!/usr/bin/env perl

use strict;
use warnings;

use Bio::SeqIO;


my $usage = "Usage: $0 <Input file> <Sequence Identifiers> <Start> <Stop> <Strand>\n";

die $usage unless (@ARGV == 5);

my ($inputFile, $identifiers, $start, $stop, $strand) = @ARGV;

die $usage unless (-e $inputFile);

my $format = 'fasta';
$format = 'fastq' if ($inputFile =~ /fastq/i);

my $seqIO = new Bio::SeqIO (
  -file   => '<' . $inputFile,
  -format => $format
);

my %identifiers = map { $_ => 1 } split /\s+/, $identifiers;

while (my $seq = $seqIO->next_seq) {
  next unless (defined $identifiers{$seq->id});
  my $sequence = substr $seq->seq, $start, ($stop - $start);
  $sequence = reverse complement ($sequence) if ($strand == -1);
  print '>' . $seq->id;
  print ' ' . $seq->description if ($seq->description ne '');
  print "\n" . $sequence . "\n";
}

sub complement {
  my $seq = shift;
  $seq =~ tr/ACGTNacgtn/TGCANtgcan/;
  return $seq;
}


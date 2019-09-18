#!/usr/bin/perl

use strict;
use warnings;

use Bio::Seq;
use Bio::SeqIO;


my $usage = "Usage: $0 <Input file> <Sequence Identifiers>\n";

die $usage unless (@ARGV >= 2);

my ($inputFile, @identifiers) = @ARGV;

die $usage unless (-e $inputFile);

my $format = 'fasta';
$format = 'fastq' if ($inputFile =~ /fastq/i);

my $seqIO = new Bio::SeqIO (
  -file   => '<' . $inputFile,
  -format => $format
);

my %seqs;
while (my $seq = $seqIO->next_seq) {
  $seqs{$seq->id} = $seq if ($seq->id ~~ @identifiers);
}

for my $id (@identifiers) {
  next unless (defined $seqs{$id});
  print '>' . $id;
  print ' ' . $seqs{$id}->description if ($seqs{$id}->description ne '');
  print "\n" . $seqs{$id}->seq . "\n";
}

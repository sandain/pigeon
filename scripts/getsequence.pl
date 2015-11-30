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

while (my $seq = $seqIO->next_seq) {
  if ($seq->id ~~ @identifiers) {
    print '>' . $seq->id;
    print ' ' . $seq->description if ($seq->description ne '');
    print "\n" . $seq->seq . "\n";
  }
}

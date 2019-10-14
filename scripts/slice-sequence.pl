#!/usr/bin/env perl

use strict;
use warnings;

use Bio::Seq;
use Bio::SeqIO;

my $usage = "Usage: $0 <Input file> <Sequence Identifier> <Start> <Stop> <Strand>\n";

die $usage unless (@ARGV >= 2);

my ($inputFile, $identifier, $start, $stop, $strand) = @ARGV;

die $usage unless (-e $inputFile);

$start = 1 unless (defined $start);
$strand = 1 unless (defined $strand);

my $format = 'fasta';
$format = 'fastq' if ($inputFile =~ /fastq/i);

my $seqIO = new Bio::SeqIO (
  -file   => '<' . $inputFile,
  -format => $format
);

my $outputIO = new Bio::SeqIO (
  -format => 'fasta',
  -fh => \*STDOUT,
);

while (my $seq = $seqIO->next_seq) {
  next unless ($seq->id =~ /$identifier/g);
  $stop = $seq->length unless (defined $stop);
  my $sequence = substr $seq->seq, $start, ($stop - $start);
  $sequence = reverse complement ($sequence) if ($strand == -1);
  my $newSeq = new Bio::Seq (
    -id   => $seq->id,
    -desc => $seq->desc,
    -seq  => $sequence
  );
  $outputIO->write_seq ($newSeq);
}
$outputIO->close ();

sub complement {
  my $seq = shift;
  $seq =~ tr/ACGTNacgtn/TGCANtgcan/;
  return $seq;
}


#!/usr/bin/perl

use strict;
use warnings;

use Bio::Seq;
use Bio::SeqIO;


my $usage = "Usage: $0 <Input file> <Output file>\n";

die $usage if (@ARGV != 2);

my ($inputFile, $outputFile) = @ARGV;


my $inputIO = new Bio::SeqIO (
  -file   => '<' . $inputFile,
  -format => 'fasta'
);

my $outputIO = new Bio::SeqIO (
  -file   => '>' . $outputFile,
  -format => 'fasta'
);


while (my $inputSeq = $inputIO->next_seq) {
  my $seq = reverse lc $inputSeq->seq;
  # Make sure we are only working with DNA.
  if ($seq =~ /([^acgt])/) {
    die "Unrecognized character '" . $1 . "' in sequence '" . $inputSeq->id . "'\n";
  }
  # Complement the sequence.
  $seq =~ tr/acgt/tgca/;
  # Output the sequence.
  my $outputSeq = new Bio::Seq (
    -id   => $inputSeq->id,
    -desc => $inputSeq->desc,
    -seq  => $seq
  );
  $outputIO->write_seq ($outputSeq);
}

$inputIO->close;
$outputIO->close;

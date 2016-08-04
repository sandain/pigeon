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

while (my $seq = $inputIO->next_seq) {
  # Reverse complement only works with DNA and RNA.
  unless ($seq->alphabet =~ /[dr]na/) {
   die "Error: Alphabet not recognized for sequence: " . $seq->id . ".\n";
  }
  # Output the reverse complement of the sequence.
  $outputIO->write_seq ($seq->revcom);
}

$inputIO->close;
$outputIO->close;

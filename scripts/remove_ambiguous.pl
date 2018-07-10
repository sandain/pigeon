#!/usr/bin/env perl

use strict;
use warnings;

use Bio::SeqIO;

my $usage = "Usage: $0 <input fasta> <output fasta>\n";

## Check command line arguments.
die $usage if (@ARGV != 2);

my ($inputFile, $outputFile) = @ARGV;

# Make sure the input fasta file exists.
die "Input file not found!\n" if (! -e $inputFile);

# Create a SeqIO object for the input fasta file.
my $inputIO = new Bio::SeqIO (
  -file   => '<' . $inputFile,
  -format => 'fasta'
);

# Create a SeqIO object for the output fasta file.
my $outputIO = new Bio::SeqIO (
  -file   => '>' . $outputFile,
  -format => 'fasta'
);

while (my $seq = $inputIO->next_seq) {
  # Ignore any sequences with ambiguous bases.
  next if ($seq->seq =~ /[rywsmkbdhvnRYWSMKBDHVN]/);
  # Write the sequence to the output fasta file.
  $outputIO->write_seq ($seq);
}

$inputIO->close;
$outputIO->close;

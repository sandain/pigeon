#! /usr/bin/perl

use strict;
use warnings;

use Bio::Seq;
use Bio::SeqIO;

my $usage = "Usage: $0 <input fasta> <output fasta> <minimum> <maximum, optional>\n";

## Check command line argument.
die $usage if (@ARGV < 3);

my ($inputFile, $outputFile, $minimum, $maximum) = @ARGV;

# Define the maximum as a really high number by default.
$maximum = ~0 if (not defined $maximum or $maximum eq '');

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

# Check the length of each sequence.
while (my $seq = $inputIO->next_seq) {
  next if ($seq->length < $minimum);
  next if ($seq->length > $maximum);
  # Output the sequence.
  $outputIO->write_seq ($seq);
}
# Close the SeqIO objects.
$inputIO->close ();
$outputIO->close ();

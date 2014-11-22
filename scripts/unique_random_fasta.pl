#! /usr/bin/perl

use strict;
use warnings;

use Bio::Seq;
use Bio::SeqIO;

## Check command line argument.
if ( @ARGV < 1 ) {
  print "Usage: $0 <fasta> <number>\n";
  exit 1;
}

my ($fastaFile, $number) = @ARGV;

# Make sure the input fasta file exists.
if (! -e $fastaFile) {
  print "Input file not found!\n";
  exit 1;
}

# Create a SeqIO object for the input fasta file.
my $fastaIO = new Bio::SeqIO (
  -file   => '<' . $fastaFile,
  -format => 'fasta'
);

# Add each sequence in the fasta file to a hash with the key being the sequence
# identifier.  Preserve the order of sequences by storing the sequence
# identifiers in an array.
my @ids;
my %sequences;
my %genotypes;

while (my $seq = $fastaIO->next_seq) {
  # Only work with sequences that have the standard nucleotide codes (no IUPAC
  # alternative codes or gaps).
  next unless ($seq->seq =~ /^[acgt]*$/i);
  # Only add the first occurrence of each genotype to the list of sequences.
  if (not defined $genotypes{$seq->seq}) {
    $genotypes{$seq->seq} = 1;
    push @ids, $seq->id;
    $sequences{$seq->id} = $seq;
  }
}

# Undefine the genotypes hash, we are done with it.
undef %genotypes;

# Close the SeqIO object.
$fastaIO->close;
undef $fastaIO;

# If the number of available sequences is smaller than the number requested, 
# or if number is not defined, just return the available sequences.
$number = scalar @ids if (not defined $number or $number > scalar @ids);

# Output the necessary number of sequences.
for (my $i = 0; $i < $number; $i ++) {
  # Choose a random sequence from the list.
  my $index = int(rand(scalar @ids));
  my $seq = $sequences{$ids[$index]};
  # Remove the sequence from further consideration.
  splice (@ids, $index, 1);
  # Output the sequence.
  print ">" . $seq->id;
  print ' ' . $seq->description if (defined $seq->description);
  print "\n";
  print $seq->seq . "\n";
}

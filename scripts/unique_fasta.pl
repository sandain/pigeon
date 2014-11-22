#! /usr/bin/perl

use strict;
use warnings;

use Bio::Seq;
use Bio::SeqIO;

## Check command line argument.
if ( @ARGV < 1 ) {
  print "Usage: $0 <fasta>\n";
  exit 1;
}

my ($fastaFile) = @ARGV;

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

my %genotypes;
while (my $seq = $fastaIO->next_seq) {
  # Only add the first occurrence of each genotype to the list of sequences.
  if (not defined $genotypes{$seq->seq}) {
    $genotypes{$seq->seq} = $seq;
  }
}
# Close the SeqIO object.
$fastaIO->close;


foreach my $genotype (keys %genotypes) {
  # Output the sequence.
  print ">" . $genotypes{$genotype}->id;
  print ' ' . $genotypes{$genotype}->description if (defined $genotypes{$genotype}->description);
  print "\n";
  print $genotypes{$genotype}->seq . "\n";
}

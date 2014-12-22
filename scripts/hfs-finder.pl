#! /usr/bin/perl

use strict;
use warnings;

use Bio::Seq;
use Bio::SeqIO;

## Check command line argument.
if ( @ARGV < 2 ) {
  print "Usage: $0 <input fasta> <output fasta> <cutoff, optional>\n";
  exit 1;
}

my ($inputFile, $outputFile, $cutoff) = @ARGV;

$cutoff = 0 if (not defined $cutoff or $cutoff eq '');

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

# Load each genotype.
my %genotypes;
while (my $seq = $inputIO->next_seq) {
  push @{$genotypes{$seq->seq}}, $seq;
}
# Close the SeqIO object.
$inputIO->close;

# Output the first representative sequence of each genotype.
my $seqnum = 0;
foreach my $genotype (keys %genotypes) {
  if (@{$genotypes{$genotype}} > $cutoff) {
    my $seq = $genotypes{$genotype}[0];
    $seqnum ++;
    $outputIO->write_seq (
      new Bio::Seq (
        -id   => 'HFS' . $seqnum,
        -seq  => $seq->seq,
        -desc => ''
      )
    );
  }
}

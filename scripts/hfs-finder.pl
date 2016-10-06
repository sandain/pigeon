#! /usr/bin/perl

use strict;
use warnings;

use Bio::Seq;
use Bio::SeqIO;

my $usage = "Usage: $0 <input fasta> <output fasta> <HFS cutoff, optional> <LFS cutoff, optional>\n";

## Check command line argument.
die $usage if (@ARGV < 2);

my ($inputFile, $outputFile, $hfsCutoff, $lfsCutoff) = @ARGV;

# A HFS cutoff of 0 is the same as a cutoff of 1.
$hfsCutoff = 0 if (not defined $hfsCutoff or $hfsCutoff eq '');
# Define the LFS cutoff as a really high number by default.
$lfsCutoff = ~0 if (not defined $lfsCutoff or $lfsCutoff eq '' or $hfsCutoff == 0);

# Make sure the input fasta file exists.
die "Input file not found!\n" if (! -e $inputFile);

# Create a SeqIO object for the input fasta file.
my $inputIO = new Bio::SeqIO (
  -file   => '<' . $inputFile,
  -format => 'fasta'
);

# Load each genotype.
my %genotypes;
while (my $seq = $inputIO->next_seq) {
  # Ignore any sequences with ambiguous bases.
  next if ($seq->seq =~ /[rywsmkbdhvnRYWSMKBDHVN]/);
  # Add the sequence to the list of genotypes.
  $genotypes{$seq->seq} ++;
}
# Close the SeqIO object.
$inputIO->close ();

# Create a SeqIO object for the output fasta file.
my $outputIO = new Bio::SeqIO (
  -file   => '>' . $outputFile,
  -format => 'fasta'
);

# Output arepresentative sequence of each genotype.
my $hfsNum = 0;
my $lfsNum = 0;
foreach my $seq (sort { $genotypes{$b} <=> $genotypes{$a} } keys %genotypes) {
  my $id = 'null';
  if ($genotypes{$seq} >= $hfsCutoff) {
    $id = sprintf "HFS%04d", $hfsNum;
    $hfsNum ++;
  }
  elsif ($genotypes{$seq} >= $lfsCutoff) {
    $id = sprintf "LFS%04d", $lfsNum;
    $lfsNum ++;
  }
  next if ($id eq 'null');
  $outputIO->write_seq (
    new Bio::Seq (
      -id   => $id,
      -seq  => $seq,
      -desc => $genotypes{$seq}
    )
  );
}
$outputIO->close ();

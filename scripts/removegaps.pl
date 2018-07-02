#!/usr/bin/env perl

use strict;
use warnings;

use Bio::Seq;
use Bio::SeqIO;
use FileHandle;

my $usage = "Usage: $0 <Input file> <Output file>\n";

die $usage unless (@ARGV == 2);

my ($inputFile, $outputFile) = @ARGV;

die $usage unless (-e $inputFile);

# Create a SeqIO object for the input fasta file.
my $inputFH = new FileHandle ($inputFile, 'r');
my $inputIO = new Bio::SeqIO (-fh => $inputFH, -format => 'fasta');

# Create a SeqIO object for the output fasta file.
my $outputFH = new FileHandle ($outputFile, 'w');
my $outputIO = new Bio::SeqIO (-fh => $outputFH, -format => 'fasta');

# Find the set of gaps for the sequences in the input file.
my %gaps;
while (my $seq = $inputIO->next_seq) {
  my $sequence = $seq->seq;
  # Change ambiguous bases (N or n) to gaps.
  $sequence =~ s/N/-/ig;
  # Check each base in the sequence for a gap.
  for (my $i = 0; $i < length $sequence; $i ++) {
    next if (defined $gaps{$i});
    my $nuc = substr $sequence, $i, 1;
    $gaps{$i} = 1 if ($nuc eq '-');
  }
}

# Sort the list of gaps in decreasing order.
my @gaps = sort {$b <=> $a} keys %gaps;

printf "%s\n", join " ", @gaps;

# Seek to the beginning of the input file.
seek $inputFH, 0, 0;

# Remove gaps from each sequence in the input file and write it to the output
# file.
while (my $seq = $inputIO->next_seq) {
  my $sequence = $seq->seq;
  foreach my $gap (@gaps) {
    substr $sequence, $gap, 1, '';
  }
  my $outSeq = new Bio::Seq (
    -id   => $seq->id,
    -seq  => $sequence,
    -desc => $seq->desc
  );
  $outputIO->write_seq ($outSeq);
}

# Close the input and output files.
$inputIO->close;
$outputIO->close;

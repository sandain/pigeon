#!/usr/bin/perl

use strict;
use warnings;
 
use Bio::SeqIO;

my $usage = "Usage: $0 <Fasta input file> <Phylip output file>\n";

die $usage unless (@ARGV == 2);

my ($fastaFile, $phylipFile) = @ARGV;

# Verify that the input file exists.
die "Unable to read from the input Fasta!\n" unless (-e $fastaFile);

# SeqIO object for the fasta file.
my $fastaIO = Bio::SeqIO->new (
  -file   => '<' . $fastaFile,
  -format => 'fasta',
);

my $num = 0;
my $length = 0;
my @seqs;

# Loop though all of the sequences of the fasta file.
while (my $seq = $fastaIO->next_seq) {
  $num ++;
  $length = $seq->length if ($seq->length > $length);
  push @seqs, $seq;
}

open PHYLIP, '>' . $phylipFile or die "Unable to write to the output Phylip file: $!\n";
print PHYLIP $num . "\t" . $length . "\n";
for (my $i = 0; $i < @seqs; $i ++) {
  die "Error, all sequences must be of the same length.\n" if ($seqs[$i]->length ne $length);
  my $id = $seqs[$i]->id;
  if (length $id > 10) {
    $id = substr ($id, 0, 10);
    printf STDERR "Identifier too long, truncated: %s -> %s\n", $seqs[$i]->id, $id;
  }
  printf PHYLIP "%-10s %s\n", $id, $seqs[$i]->seq;
}
close PHYLIP;

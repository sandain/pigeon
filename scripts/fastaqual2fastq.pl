#!/usr/bin/perl

use strict;
use warnings;
 
use Bio::SeqIO;
use Bio::Seq::Quality;
 

my $usage = "Usage: $0 <fasta input file> <quality input file> <fastq output file>\n";

if (@ARGV != 3) {
  print $usage;
  exit;
}

my ($fastaFile, $qualFile, $fastqFile) = @ARGV;

# Verify that the input files exist.
if (! -e $fastaFile or ! -e $qualFile) {
  print "Input file(s) not found!\n";
  print $usage;
  exit 1;
}

# SeqIO object for the fasta file.
my $fastaIO = Bio::SeqIO->new (
  -file   => '<' . $fastaFile,
  -format => 'fasta',
);

# SeqIO object for the qual file.
my $qualIO = Bio::SeqIO->new (
  -file   => '<' . $qualFile,
  -format => 'qual',
);

# SeqIO object for the fastq file.
my $fastqIO = Bio::SeqIO->new (
  -file   => '>' . $fastqFile,
  -format => 'fastq'
);

# Loop though all of the sequences of the fasta and qual files.
while (my $seq = $fastaIO->next_seq) {
  my $qual = $qualIO->next_seq;
  # Make sure that the identifiers from the fasta and qual files match.
  if ($seq->id ne $qual->id) {
    print "The order of sequences in the fasta and qual files do not match.\n";
    exit 1;
  }
  # Create a new Quality object to hold the sequence and quality data.
  my $fastq = Bio::Seq::Quality->new (
    -id   => $seq->id,
    -seq  => $seq->seq,
    -qual => $qual->qual,
    -desc => $seq->desc
  );
  # Write the Quality object to the fastq file.
  $fastqIO->write_fastq($fastq);
}
# Close the file handles.
$fastaIO->close;
$qualIO->close;
$fastqIO->close;

#! /usr/bin/perl

use strict;
use warnings;

use Bio::Seq;
use Bio::SeqIO;

## Check command line argument.
if (@ARGV == 0) {
  die "Usage: $0 <fastq file name> <fasta file name> <optional desc>\n";
}

my ($fastqFile, $fastaFile, $desc) = @ARGV;

# Make sure the input fastq file exists.
if (! -e $fastqFile) {
  die "Input file not found!\n";
}

# Create a SeqIO object for the input fastq file.
my $fastqIO = new Bio::SeqIO (
  -file   => '<' . $fastqFile,
  -format => 'fastq'
);

# Create a SeqIO object for the output fasta file.
my $fastaIO = new Bio::SeqIO (
  -file   => '>' . $fastaFile,
  -format => 'fasta'
);

# Write each sequence in the fastq file to the fasta file.
while (my $seq = $fastqIO->next_seq) {
  my $newSeq = new Bio::Seq (
    -id   => $seq->id,
    -seq  => $seq->seq,
    -desc => (defined $desc ? $desc . " " : "") . $seq->desc
  );
  $fastaIO->write_seq ($newSeq);
}

# Close the SeqIO objects.
$fastqIO->close;
$fastaIO->close;

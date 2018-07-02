#! /usr/bin/perl

use strict;
use warnings;

use Bio::Seq;
use Bio::SeqIO;
use IO::Uncompress::Gunzip;
use IO::Uncompress::Bunzip2;
use FileHandle;

## Check command line argument.
if (@ARGV == 0) {
  die "Usage: $0 <fastq file name> <fasta file name> <optional desc>\n";
}

my ($fastqFile, $fastaFile, $desc) = @ARGV;

# Make sure the input fastq file exists.
if (! -e $fastqFile) {
  die "Input file not found!\n";
}

# Handle sequence files that are compressed with gzip or bzip2.
my $fh;
if ($fastqFile =~ /\.t?gz/) {
  $fh = new IO::Uncompress::Gunzip ($fastqFile);
}
elsif ($fastqFile =~ /\.t?bz2/) {
  $fh = new IO::Uncompress::Bunzip2 ($fastqFile);
}
else {
  $fh = new FileHandle ($fastqFile);
}

# Create a SeqIO object for the input fastq file.
my $fastqIO = new Bio::SeqIO (
  -fh   => $fh,
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

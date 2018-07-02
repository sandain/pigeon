#!/bin/perl

use strict;
use warnings;

use Bio::SeqIO;
use IO::Uncompress::Gunzip;
use IO::Uncompress::Bunzip2;
use FileHandle;

my $usage = "Usage: $0 <Sequence File> <Partition Size> <Output Prefix>\n";

die $usage unless (@ARGV == 3);

my ($sequenceFile, $partitionSize, $outputPrefix) = @ARGV;

# Handle sequence files that are compressed with gzip or bzip2.
my $fh;
if ($sequenceFile =~ /\.t?gz/) {
  $fh = new IO::Uncompress::Gunzip ($sequenceFile);
}
elsif ($sequenceFile =~ /\.t?bz2/) {
  $fh = new IO::Uncompress::Bunzip2 ($sequenceFile);
}
else {
  $fh = new FileHandle ($sequenceFile);
}

# Attempt to detect the format of the sequence file.
my $format = "fasta";
$format = "fastq" if ($sequenceFile =~ /fastq/);

my $seqIO = new Bio::SeqIO (
  -fh   => $fh,
  -format => $format
);

my $outputCounter = 0;
my $sequenceCounter = 0;
my $outIO = new Bio::SeqIO (
  -file   => sprintf (">%s.%05d.fa", $outputPrefix, $outputCounter),
  -format => 'fasta'
);

while (my $seq = $seqIO->next_seq) {
  if ($sequenceCounter >= $partitionSize) {
    $sequenceCounter = 0;
    $outputCounter ++;
    $outIO->close ();
    $outIO = new Bio::SeqIO (
      -file   => sprintf (">%s.%05d.fa", $outputPrefix, $outputCounter),
      -format => 'fasta'
    );
  }
  $outIO->write_seq ($seq);
  $sequenceCounter ++;
}
$outIO->close ();

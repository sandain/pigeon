#!/usr/bin/perl

use strict;
use warnings;

use Bio::SeqIO;

my $usage = "Usage: $0 <fastq input file> <fastq output file>\n";

# Make sure that the proper number of arguments were supplied.
if (@ARGV != 2) {
  die $usage;
}

# Grab the input and output file names.
my ($inFile, $outFile) = @ARGV;

# Handle input files that are compressed with gzip.
if ($inFile =~ /\.t?gz/) {
  $inFile = "gunzip -c $inFile |";
}

# Handle input files that are compressed with bzip2.
if ($inFile =~ /\.t?bz2?/) {
  $inFile = "bunzip2 -c $inFile |";
}

# Determine the formats to use for the input and output files.
my $outFormat = "fastq-sanger";
my $inFormat = guessFormat ($inFile);

# Make sure that the input file format was detected.
if (not defined $inFormat) {
  die "Error, unable to determine the format of file: $inFile\n";
}

# Create a SeqIO object for the input and output fastq files.
my $inIO = new Bio::SeqIO (
  -file   => $inFile,
  -format => $inFormat
);
my $outIO = new Bio::SeqIO (
  -file   => '>' . $outFile,
  -format => $outFormat
);

print "Input format: $inFormat\n";
print "Output format: $outFormat\n";

# Write each sequence in the input file to the output file.
my $counter = 0;
while (my $seq = $inIO->next_seq) {
  $outIO->write_seq ($seq);
  $counter ++;
}

print "Converted $counter sequences\n";

# Close the SeqIO objects.
$inIO->close;
$outIO->close;


# Guess which language the fastq file uses (fastq-sanger, fastq-solexa, fastq-illumina).
sub guessFormat {
  my ($file) = @_;
  my %format = (
    "fastq-sanger"   => 0,
    "fastq-illumina" => 0,
    "fastq-solexa"   => 0
  );
  # Open the input file.
  open INPUT, $file or die "Unable to read from file $file: $!\n";
  # Check the quality scores of each record in the file.
  my $inQuality = 0;
  while (my $line = <INPUT>) {
    $line =~ s/[\r\n]+//g;
    # Look for the start of a new sequence record.
    if ($line =~ /^\@([\w\:\.\#\/]+)\s*(.*)$/) {
      $inQuality = 0;
      next;
    }
    # Look for the start of the quality data for this record.
    if ($inQuality == 0 and $line =~ /^\+.*$/) {
      $inQuality = 1;
      next;
    }
    # Look for quality data in the Sanger format.
    if ($inQuality == 1 and $line =~ /^([\x21-\x4a])+$/) {
      $format{"fastq-sanger"} ++;
      next;
    }
    # Look for quality data in the Illumina format.
    if ($inQuality == 1 and $line =~ /^([\x40-\x68])+$/) {
      $format{"fastq-illumina"} ++;
      next;
    }
    # Look for quality data in the Solexa format.
    if ($inQuality == 1 and $line =~ /^([\x3B-\x68])+$/) {
      $format{"fastq-solexa"} ++;
      next;
    }
  }
  # Close the input file.
  close INPUT;
  # Return the format type of the fastq file.
  return "fastq-solexa" if ($format{"fastq-solexa"} > 0);
  return "fastq-illumina" if ($format{"fastq-illumina"} > 0);
  return "fastq-sanger" if ($format{"fastq-sanger"} > 0);
}

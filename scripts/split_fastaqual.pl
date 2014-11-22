#! /usr/bin/perl

use strict;
use warnings;

use Bio::Seq;
use Bio::SeqIO;

## Check command line argument.
if (@ARGV != 3) {
  print "Usage: $0 <combined fasta/qual file name> <fasta file name> <qual file name>\n";
  exit 1;
}

my ($combinedFile, $fastaFile, $qualFile) = @ARGV;

# Make sure the input combined file exists.
if (! -e $combinedFile) {
  print "Input file not found!\n";
  exit 1;
}

# Create a SeqIO object for the fasta file.
my $fastaIO = new Bio::SeqIO (
  -file   => '>' . $fastaFile,
  -format => 'fasta'
);

# Create a SeqIO object for the quality file.
my $qualIO = new Bio::SeqIO (
  -file   => '>' . $qualFile,
  -format => 'qual'
);

# Load the combined fasta/quality file.
open COMBINED, $combinedFile or die "Unable to load input file: $!\n";
# Remove the default input record separator.
undef $/;
# Load the combined fasta/quality file, breaking up each sub-record into chunks (split on '>').
my @chunks = split(/>/, <COMBINED>);
close COMBINED;
# The first chunk is empty.
shift @chunks;

for (my $i = 0; $i < @chunks; $i += 2) {
  # Build a new sequence object, and write it to the fasta file.
  my ($header, $data) = split /[\r\n]+/, $chunks[$i], 2;
  my ($id, $desc) = split /\s+/, $header, 2;
  $data =~ s/[\r\n]+//g;
  my $seq = Bio::Seq->new (
    -id   => $id,
    -desc => $desc,
    -seq  => $data
  );
  $fastaIO->write_seq ($seq);
  # Build a new quality object, and write it to the quality file.
  ($header, $data) = split /[\r\n]+/, $chunks[$i + 1], 2;
  my $qual = Bio::Seq::PrimaryQual->new (
    -id   => $id,
    -desc => $desc,
    -qual => $data,
  );
  $qualIO->write_seq ($qual);
}

# Close the output files.
$fastaIO->close;
$qualIO->close;

#! /usr/bin/perl

use strict;
use warnings;

use Bio::Seq::Quality;
use Bio::SeqIO;

my @decode = (
  { 'A' => 'A', 'C' => 'C', 'G' => 'G', 'T' => 'T' },
  { 'A' => 'C', 'C' => 'A', 'G' => 'T', 'T' => 'G' },
  { 'A' => 'G', 'G' => 'A', 'C' => 'T', 'T' => 'C' },
  { 'A' => 'T', 'T' => 'A', 'G' => 'C', 'C' => 'G' }
);

## Check command line argument.
if (@ARGV == 0) {
  die "Usage: $0 <color space fastq file name> <fastq file name>\n";
}

my ($colorspaceFile, $fastqFile) = @ARGV;

# Make sure the input fastq file exists.
if (! -e $colorspaceFile) {
  die "Input file not found!\n";
}

# Create a SeqIO object for the input color-space fastq file.
my $colorspaceIO = new Bio::SeqIO (
  -file   => '<' . $colorspaceFile,
  -format => 'fastq'
);

# Create a SeqIO object for the output fastq file.
my $fastqIO = new Bio::SeqIO (
  -file   => '>' . $fastqFile,
  -format => 'fastq'
);

# Write each sequence in the color-space fastq file to the output fastq file.
while (my $seq = $colorspaceIO->next_seq) {
  # Decode the color-space sequence string into a nucleotide-space string.
  my $colorspace = uc $seq->seq;
  my $primer = '';
  my $sequence = '';
  foreach my $char (split //, $colorspace) {
    if ($primer eq 'N') {
      $sequence .= $primer;
      next; 
    }
    if ($char =~ /[ACGT]/) {
      $primer = $char if ($primer eq '');
    }
    elsif ($char =~ /[\d]/) {
      $primer = $decode[$char]->{$primer};
      $sequence .= $primer;
    }
    elsif ($char eq '.') {
      $primer = 'N';
      $sequence .= $primer;
    }
    else {
      print "Unknown character: " . $char . "\n";
    }
  }
  # Remove the quality score of the primer.
  my $quality = $seq->qual;
  if ($colorspace =~ /^[ACGT]/) {
    shift @{$quality};
  }
  if ($colorspace =~ /[ACGT]$/) {
    pop @{$quality};
  }
  # Write the decoded sequence to the output fastq file.
  my $newSeq = new Bio::Seq::Quality (
    -id   => $seq->id,
    -desc => $seq->desc,
    -seq  => $sequence,
    -qual => $quality
  );
  $fastqIO->write_seq ($newSeq);
}

$colorspaceIO->close;
$fastqIO->close;


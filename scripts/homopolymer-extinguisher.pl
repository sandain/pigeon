#! /usr/bin/perl

use strict;
use warnings;

use Bio::Seq;
use Bio::SeqIO;
use File::Temp;

# Grab command line input, return an error if not enough input provided.
my $usage = "Usage: $0 <Reference Sequence File> <Raw Sequence File> <Output Sequence File> <Trim, default 1> <Remove Gaps, default 1>\n";
die $usage unless (@ARGV >= 3);
my ($refFile, $rawFile, $outputFile, $trim, $removeGaps, $removeShort) = @ARGV;

# Check to make sure that CLUSTAL is installed.
my $clustalBin = `which clustalw`;
$clustalBin =~ s/[\r|\n]//g;
die "Unable to find the executable for CLUSTAL, make sure that it is installed!\n" unless (-e $clustalBin);


# Default trim, removeGaps, and removeShort to 1.
if (not defined $trim or (defined $trim and not $trim == 0)) {
  $trim = 1;
}
if (not defined $removeGaps or (defined $removeGaps and not $removeGaps == 0)) {
  $removeGaps = 1;
}
if (not defined $removeShort or (defined $removeShort and not $removeShort == 0)) {
  $removeShort = 1;
}

# Grab the reference sequence.
my $refSeqIO = new Bio::SeqIO (
  -file   => '<' . $refFile,
  -format => 'fasta'
);

# Grab the raw sequences.
my $rawSeqIO = new Bio::SeqIO (
  -file   => '<' . $rawFile,
  -format => 'fasta'
);

# Create the output file.
my $outSeqIO = new Bio::SeqIO (
  -file   => '>' . $outputFile,
  -format => 'fasta'
);

while (my $raw = $rawSeqIO->next_seq) {
  # Find the best alignment between this raw sequence and the reference sequences.
  my ($refSeq, $refSeqID, $rawSeq);
  my $score = 0;
  # Check each possible combination of alignment.
  my @rawSeqs;
  $rawSeqs[0] = $raw->seq;
  $rawSeqs[1] = reverse $rawSeqs[0];
  $rawSeqs[2] = compliment ($rawSeqs[0]);
  $rawSeqs[3] = reverse $rawSeqs[2];
  # Seek to the beginning of the reference sequence file.
  seek $refSeqIO->_fh, 0, 0;
  while (my $ref = $refSeqIO->next_seq) {
    foreach my $seq (@rawSeqs) {
      # Align the reference and raw sequences.
      my @align = align (
        $ref->seq,
        $seq
      );
      if ($align[2] > $score) {
        ($refSeq, $rawSeq, $score) = @align;
        $refSeqID = $ref->id;
      }
    }
  }
  my $seq;
  # Trim any nucleotides that created a gap in the reference sequence.
  if ($trim) {
    $seq = trim ($refSeq, $rawSeq);
  }
  else {
    $seq = $rawSeq;
  }
  # Keep any aligned and trimmed sequences that are the correct length,
  # and only those that have no gaps, unless requested.
  if (
     not ($seq =~ /^--+/ and $removeShort) and 
     not ($seq =~ /--+$/ and $removeShort) and
     not ($seq =~ /-/ and $removeGaps)
  ) {
    # Remove any gaps that survived to this point.
    $seq =~ s/-//g;
    my $temp = new Bio::Seq (
      -id   => $raw->id,
      -desc => 'refseq=' . $refSeqID . ' ' . $raw->desc,
      -seq  => $seq
    );
    $outSeqIO->write_seq ($temp);
  }
}

# Close the SeqIO objects.
$refSeqIO->close;
$rawSeqIO->close;
$outSeqIO->close;


sub trim {
  my ($seqA, $seqB) = @_;
  my $seq = '';
  for (my $i = 0; $i < length $seqA; $i ++) {
    if (substr ($seqA, $i, 1) ne '-') {
      $seq .= substr ($seqB, $i, 1);
    }
  }
  return $seq;
}

sub align {
  my ($seqA, $seqB) = @_;
  my ($sequenceA, $sequenceB, $score); 
  # Create a temporary files for the alignment.
  my $inputFH = new File::Temp();
  my $outputFH = new File::Temp();
  my $inputFile = $inputFH->filename();
  my $outputFile = $outputFH->filename();
  # Write the sequences to the input FASTA file.
  print $inputFH ">seqa\n$seqA\n>seqb\n$seqB\n";
  # Align the two sequences.
  my $output = `$clustalBin -align -infile=$inputFile -outfile=$outputFile -output=fasta`;
  # Remove the generated newick tree, it is unneeded.
  unlink "$inputFile.dnd";
  # Grab the alignment score.
  if ($output =~ /Alignment Score (\d+)/ ) {
    $score = $1;
  }
  # Create a new SeqIO object from the alignment output.
  my $seqIO = new Bio::SeqIO (
    -fh     => $outputFH,
    -format => 'fasta'
  );
  # Grab the two sequences from the SeqIO object.
  while (my $seq = $seqIO->next_seq) {
    if ($seq->id eq 'seqa') {
      $sequenceA = $seq->seq;
    }
    if ($seq->id eq 'seqb') {
      $sequenceB = $seq->seq;
    }
  }
  return ($sequenceA, $sequenceB, $score);
}

sub compliment {
  my $seq = shift;
  $seq =~ tr/ACGTacgt/TGCAtgca/;
  return $seq;
}


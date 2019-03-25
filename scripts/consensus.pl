#! /usr/bin/perl

use strict;
use threads;
use warnings;

use Bio::Seq;
use Bio::Seq::Quality;
use Bio::SeqIO;
use File::Temp;

my $usage = "Usage: $0 <Forward Sequence> <Reverse Sequence> <Output File>";

my $cutoff = 35;

# Return the usage statement if not enough command line input provided.
die $usage unless (@ARGV == 3);

# Grab the command line variables.
my ($forwardFile, $reverseFile, $outFile) = @ARGV;

# Check to make sure that Clustal Omega is installed.
my $clustalBin = `which clustalo`;
$clustalBin =~ s/[\r|\n]//g;
die "Unable to find the executable for CLUSTAL!\n" unless (-e $clustalBin);

# Align two Bio::Seq sequences using Clustal Omega.
sub align {
  my ($a, $b) = @_;
  my ($seqA, $seqB);
  # Make a copy of the two sequences.
  if (ref ($a) eq 'Bio::Seq::Quality') {
    $seqA = new Bio::Seq::Quality (
      -id   => $a->id,
      -seq  => $a->seq,
      -qual => $a->qual,
      -desc => $a->desc
    );
  }
  else {
    $seqA = new Bio::Seq (
      -id   => $a->id,
      -seq  => $a->seq,
      -desc => $a->desc
    );
  }
  if (ref ($b) eq 'Bio::Seq::Quality') {
    $seqB = new Bio::Seq::Quality (
      -id   => $b->id,
      -seq  => $b->seq,
      -qual => $b->qual,
      -desc => $b->desc
    );
  }
  else {
    $seqB = new Bio::Seq (
      -id   => $b->id,
      -seq  => $b->seq,
      -desc => $b->desc
    );
  }
  # Create a temporary files for the alignment.
  my $inputFH = new File::Temp ();
  my $outputFH = new File::Temp ();
  my $inputFile = $inputFH->filename ();
  my $outputFile = $outputFH->filename ();
  # Write the sequences to the input FASTA file.
  printf $inputFH ">seqa\n%s\n>seqb\n%s\n", $seqA->seq, $seqB->seq;
  # Align the two sequences.
  my $output = `$clustalBin --infile=$inputFile --outfile=$outputFile --force`;
  # Create a new SeqIO object from the alignment output.
  my $seqIO = new Bio::SeqIO (
    -fh     => $outputFH,
    -format => 'fasta'
  );
  # Grab the two sequences from the SeqIO object.
  while (my $seq = $seqIO->next_seq) {
    if ($seq->id eq 'seqa') {
      $seqA->seq ($seq->seq);
      if (ref ($seqA) eq 'Bio::Seq::Quality') {
        my @qual = @{$seqA->qual};
        for (my $i = 0; $i < length $seq->seq; $i ++) {
          splice (@qual, $i, 0, 0) if (substr ($seq->seq, $i, 1) eq '-');
        }
        $seqA->qual (join ' ', @qual);
      }
    }
    if ($seq->id eq 'seqb') {
      $seqB->seq ($seq->seq);
      if (ref ($seqB) eq 'Bio::Seq::Quality') {
        my @qual = @{$seqB->qual};
        for (my $i = 0; $i < length $seq->seq; $i ++) {
          splice (@qual, $i, 0, 0) if (substr ($seq->seq, $i, 1) eq '-');
        }
        $seqB->qual (join ' ', @qual);
      }
    }
  }
  return ($seqA, $seqB);
}

# Reverse complement a Bio::Seq sequence.
sub complement {
  my $seq = shift;
  my $sequence = reverse $seq->seq;
  $sequence =~ tr/ACGTNacgtn/TGCANtgcan/;
  if (ref ($seq) eq 'Bio::Seq::Quality') {
    my @quality = reverse @{$seq->qual};
    return new Bio::Seq::Quality (
      -id   => $seq->id,
      -seq  => $sequence,
      -qual => \@quality,
      -desc => $seq->desc
    );
  }
  else {
    return new Bio::Seq (
      -id   => $seq->id,
      -seq  => $sequence,
      -desc => $seq->desc
    );
  }
}

# Translate to IUPAC codes.
sub iupac {
  my ($f, $r) = @_;
  # Translate RNA nucleotides.
  $f = 't' if ($f eq 'u');
  $r = 't' if ($r eq 'u');
  # Adenine or Guanine.
  if (($f eq 'a' && $r eq 'g') || ($f eq 'g' && $r eq 'a')) {
    return 'R';
  }
  # Cytosine or Thymine.
  if (($f eq 'c' && $r eq 't') || ($f eq 't' && $r eq 'c')) {
    return 'Y';
  }
  # Cytosine or Guanine.
  if (($f eq 'g' && $r eq 'c') || ($f eq 'c' && $r eq 'g')) {
   return 'S';
  }
  # Adenine or Thymine.
  if (($f eq 'a' && $r eq 't') || ($f eq 't' && $r eq 'a')) {
    return 'W';
  }
  # Guanine or Thymine.
  if (($f eq 'g' && $r eq 't') || ($f eq 't' && $r eq 'g')) {
    return 'K';
  }
  # Adenine or Cytosine.
  if (($f eq 'a' && $r eq 'c') || ($f eq 'c' && $r eq 'a')) {
    return 'M';
  }
}

# Subroutine to create a consensus sequence from two aligned sequences.
sub consensus {
  my ($forward, $reverse) = @_;
  my (@forwardQual, @reverseQual);
  @forwardQual = @{$forward->qual} if (ref ($forward) eq 'Bio::Seq::Quality');
  @reverseQual = @{$reverse->qual} if (ref ($reverse) eq 'Bio::Seq::Quality');
  my $consensus;
  for (my $i = 0; $i < length ($forward->seq); $i ++) {
    my $f = lc substr $forward->seq, $i, 1;
    my $r = lc substr $reverse->seq, $i, 1;
    if ($f eq $r && $f ne '-' && $f ne 'n') {
      # Nucleotides are equal, but not a gap or 'N'.
      if (@forwardQual > 0 && @reverseQual > 0) {
        # Quality scores exist.
        if ($forwardQual[$i] >= $cutoff && $reverseQual[$i] >= $cutoff) {
          # Both nucleotides have a high quality, return upper case.
          $consensus .= uc $f;
        }
        else {
          # At least one of the nucleotides is low quality, return lower case.
          $consensus .= $f;
        }
      }
      else {
        # Quality scores don't exist, return upper case.
        $consensus .= uc $f;
      }
    }
    elsif ($f ne $r && $f ne '-' && $f ne 'n' && $r ne '-' && $r ne 'n') {
      # Nucleotides are not equal, and neither are a gap or 'N'.
      if (@forwardQual > 0 && @reverseQual > 0) {
        # Quality scores exist.
        if ($forwardQual[$i] >= $cutoff && $reverseQual[$i] >= $cutoff) {
          # Both nucleotides have a high quality, return IUPAC code.
          $consensus .= iupac ($f, $r);
        }
        elsif ($forwardQual[$i] >= $cutoff) {
          # Forward nucleotide has a high quality, return it lower case.
          $consensus .= $f;
        }
        elsif ($reverseQual[$i] >= $cutoff) {
          # Reverse nucleotide has a high quality, return it lower case.
          $consensus .= $r;
        }
        else {
          # Niether nucleotide has a high quality, return an 'N'.
          $consensus .= 'N';
        }
      }
      else {
        # Quality scores don't exist, return IUPAC code.
        $consensus .= iupac ($f, $r);
      }
    }
    elsif ($f eq $r) {
      # Nucleotides are equal, but either a gap or 'N', return as is.
      $consensus .= $f;
    }
    else {
      # One of the nucleotides is a gap or 'N'.
      if (@forwardQual > 0 && @reverseQual > 0) {
        # Quality scores exist.
        if ($forwardQual[$i] >= $cutoff) {
          # Forward nucleotide is high quality, return it lower case.
          $consensus .= $f;
        }
        elsif ($reverseQual[$i] >= $cutoff) {
          # Reverse nucleotide is high quality, return it lower case.
          $consensus .= $r;
        }
        else {
          # There is no high quality nucleotide, return an 'N'.
          $consensus .= 'N';
        }
      }
      else {
        # Quality scores don't exist.
        if ($f ne '-' and $f ne 'n') {
          # Forward nucleotide not a gap or 'N', return it lower case.
          $consensus .= $f;
        }
        else {
          # Reverse nucleotide not a gap or 'N', return it lower case.
          $consensus .= $r;
        }
      }
    }
  }
  return new Bio::Seq (
    -id   => $forward->id,
    -seq  => $consensus,
    -desc => ''
  );
}

sub trim {
  my ($seq) = @_;
  my $t = $seq->seq;
  $t =~ s/^[-N]+//;
  $t =~ s/[-N]+$//;
  my $sequence;
  for (my $i = 0; $i < length ($t) / 2; $i ++) {
    $sequence .= substr ($t, $i, 1) unless (substr ($t, $i, 3) =~ /[-N]/i);
  }
  for (my $i = length ($t) / 2 + 1; $i < length $t; $i ++) {
    $sequence .= substr ($t, $i, 1) unless (substr ($t, $i-2, 3) =~ /[-N]/i);
  }
  $sequence =~ s/-//g;
  return new Bio::Seq (
    -id   => $seq->id,
    -seq  => $sequence,
    -desc => length $sequence
  );
}

my $forwardFormat = 'fasta';
my $reverseFormat = 'fasta';
$forwardFormat = 'fastq' if ($forwardFile =~ /fastq/i);
$reverseFormat = 'fastq' if ($reverseFile =~ /fastq/i);

# Load the forward sequence file.
my $forwardSeqIO = new Bio::SeqIO (
  -file   => '<' . $forwardFile,
  -format => $forwardFormat
);
my @forward;
while (my $seq = $forwardSeqIO->next_seq) {
  push @forward, $seq;
}
$forwardSeqIO->close;
die "Error: forward sequence file contains more than a single sequence!\n" if (@forward > 1);

# Load the reverse sequence file.
my $reverseSeqIO = new Bio::SeqIO (
  -file   => '<' . $reverseFile,
  -format => $reverseFormat
);
my @reverse;
while (my $seq = $reverseSeqIO->next_seq) {
  push @reverse, $seq;
}
$reverseSeqIO->close;
die "Error: reverse sequence file contains more than a single sequence!\n" if (@reverse > 1);

# Extract the forward sequence.
my $forward = $forward[0];

# Extract the reverse sequence, and reverse complement it.
my $reverse = complement $reverse[0];

# Align the forward and reverse sequences.
my ($alignedForward, $alignedReverse) = align ($forward, $reverse);

# Create the consensus sequence from the aligned forward and reverse sequences.
my $consensus = consensus ($alignedForward, $alignedReverse);

# Trim poor quality portions of the consensus sequence.
my $trimmed = trim ($consensus);

# Write the consensus sequence to the output file.
open OUTPUT, '>' . $outFile or die "Unable to open file for output: $!\n";
printf OUTPUT ">%s %s\n%s\n", $trimmed->id, $trimmed->desc, $trimmed->seq;
close OUTPUT;

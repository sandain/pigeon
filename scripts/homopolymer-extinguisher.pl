#! /usr/bin/perl

use strict;
use threads;
use warnings;

use Bio::Seq;
use Bio::SeqIO;
use File::Temp;
use Thread::Queue;

our $INT_MIN = -2147483648;

my $thread_limit = 20;

my $usage = "Usage: $0 <Reference Sequences> <Raw Sequences> <Output File> " .
  "<Trim, default 1> <Remove Gaps, default 1> <Remove Short, default 1>\n";

# Return the usage statement if not enough command line input provided.
die $usage unless (@ARGV >= 3);

# Grab the command line variables.
my ($refFile, $rawFile, $outFile, $trim, $removeGaps, $removeShort) = @ARGV;

# Check to make sure that CLUSTAL is installed.
my $clustalBin = `which clustalw`;
$clustalBin =~ s/[\r|\n]//g;
die "Unable to find the executable for CLUSTAL!\n" unless (-e $clustalBin);

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

sub bestAlign {
  my ($raw, $refs) = @_;
  my ($refID, $alignedRef, $alignedRaw);
  my $score = $INT_MIN;
  # Check each possible combination of alignment.
  my @rawSeqs;
  $rawSeqs[0] = $raw->seq;
  $rawSeqs[1] = reverse $rawSeqs[0];
  $rawSeqs[2] = complement ($rawSeqs[0]);
  $rawSeqs[3] = reverse $rawSeqs[2];
  foreach my $ref (@{$refs}) {
    foreach my $seq (@rawSeqs) {
      # Run each alignment in its own thread.
      my @align = align ($ref->id, $ref->seq, $seq);
      if (defined $align[3] && $align[3] > $score) {
        ($refID, $alignedRef, $alignedRaw, $score) = @align;
      }
    }
  }
  my $sequence;
  # Trim any nucleotides that created a gap in the reference sequence.
  if ($trim) {
    $sequence = trim ($alignedRef, $alignedRaw);
  }
  else {
    $sequence = $alignedRaw;
  }
  # Keep any aligned and trimmed sequences that are the correct length,
  # and only those that have no gaps, unless requested.
  if (
     not ($sequence =~ /^--+/ and $removeShort) and
     not ($sequence =~ /--+$/ and $removeShort) and
     not ($sequence =~ /-/ and $removeGaps)
  ) {
    my $desc = 'refseq=' . $refID;
    $desc .= ' ' . $raw->desc if (defined $raw->desc);
    return ($raw->id, $desc, $sequence);
  }
}

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
  my ($id, $seqA, $seqB) = @_;
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
  if ($output =~ /Alignment Score ([\-\d]+)/ ) {
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
  return ($id, $sequenceA, $sequenceB, $score);
}

sub complement {
  my $seq = shift;
  $seq =~ tr/ACGTNacgtn/TGCANtgcan/;
  return $seq;
}

# Load the reference sequences file.
my $refSeqIO = new Bio::SeqIO (
  -file   => '<' . $refFile,
  -format => 'fasta'
);
my @refs;
while (my $ref = $refSeqIO->next_seq) {
  my $seq = $ref->seq;
  $seq =~ s/-//g;
  next unless (length $seq > 0);
  my $refseq = new Bio::Seq (
    -id   => $ref->id,
    -desc => $ref->desc,
    -seq  => $seq
  );
  push @refs, $refseq;
}
# Close the reference sequences file.
$refSeqIO->close;

# Create a thread queue.
my $queue = new Thread::Queue ();

# Limit the size of the thread queue.
$queue->limit = 2 * $thread_limit;

my @threads = map {
  threads->create (
    sub {
      my @aligned = ();
      # Grab a sequence from the queue.
      while (defined (my $item = $queue->dequeue ())) {
        # Find the best alignment between the sequence from the queue with the
        # reference sequences.
        my ($id, $desc, $seq) = bestAlign ($item, \@refs);
        next unless (defined $seq);
        push @aligned, sprintf ">%s %s\n%s\n", $id, $desc, $seq;
      }
      return @aligned;
    }
  );
} 1..$thread_limit;

# Add each sequence in the raw sequences file to the thread queue.
my $rawSeqIO = new Bio::SeqIO (
  -file   => '<' . $rawFile,
  -format => 'fasta'
);
while (my $raw = $rawSeqIO->next_seq) {
  my $seq = $raw->seq;
  $seq =~ s/-//g;
  next unless (length $seq > 0);
  my $rawseq = new Bio::Seq (
    -id   => $raw->id,
    -desc => $raw->desc,
    -seq  => $seq
  );
  $queue->enqueue ($rawseq);
}
$rawSeqIO->close ();

# Signal the end of the thread queue.
$queue->end;

# Write the aligned sequences to the output file.
open OUTPUT, '>' . $outFile or die "Unable to open file for output: $!\n";
foreach my $thread (@threads) {
  my @aligned = $thread->join ();
  foreach my $seq (@aligned) {
    print OUTPUT $seq;
  }
}
close OUTPUT;

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

sub checkArgument {
  my ($arg, $vals) = @_;
  my $val = $vals->[0];
  if (defined $arg && $arg ~~ @{$vals}) {
    $val = $arg;
  }
  elsif (defined $arg) {
    die "Unrecognized argument value: $arg.\n$usage";
  }
  return $val;
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
      if ($align[3] > $score) {
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
    return new Bio::Seq (
      -id   => $raw->id,
      -desc => 'refseq=' . $refID . ' ' . $raw->desc,
      -seq  => $sequence
    );
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

# Default trim, removeGaps, and removeShort to 1.
my $bool = [1, 0];
$trim = checkArgument ($trim, $bool);
$removeGaps = checkArgument ($removeGaps, $bool);
$removeShort = checkArgument ($removeShort, $bool);

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

# Each thread gets its own temporary output file.
my @files = map { $outFile . sprintf (".%02d", $_) } 1..$thread_limit;

# Create a thread queue.
my $queue = new Thread::Queue ();
my @threads = map {
  threads->create (
    sub {
      # Open this thread's temporary output file.
      my $outSeqIO = new Bio::SeqIO (
        -file   => '>' . $files[$_-1],
        -format => 'fasta'
      );
      # Grab a sequence from the queue.
      while (my $item = $queue->dequeue ()) {
        return unless (defined $item);
        # Find the best alignment between the sequence from the queue with the
        # reference sequences.
        my ($align) = bestAlign ($item, \@refs);
        return unless (defined $align);
        # Output the alignment to this thread's temporary output file.
        $outSeqIO->write_seq ($align);
      }
      # Close this thread's temporary output file.
      $outSeqIO->close ();
    }
  );
} 1..$thread_limit;

# Load the raw sequences file.
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
  while ($queue->pending () > 2 * $thread_limit) {
    sleep 1;
  }
  $queue->enqueue ($rawseq);
}
# Close the raw sequences file.
$rawSeqIO->close ();

# Signal the end of the queue.
$queue->enqueue (undef) for 1..$thread_limit;

# Wait for the threads to finish.
foreach my $thread (@threads) {
  $thread->join ();
}

# Merge the temporary output files.
my ($inFH, $outFH);
open $outFH, '>', $outFile or die "Unable to write to $outFile: $!\n";
foreach my $file (@files) {
  open $inFH, '<', $file or die "Unable to read from $file: $!\n";
  while (my $line = <$inFH>) {
    print $outFH $line;
  }
  close $inFH;
}
close $outFH;

# Delete the temporary output files.
unlink @files;

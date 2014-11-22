#!/usr/bin/perl

use strict;
use warnings;

use Bio::Seq;
use Bio::SeqIO;
use Digest::SHA;

my $usage = "Usage: $0 <fasta file> <output file>\n";

die $usage if (@ARGV == 0);

my ($file, $output) = @ARGV;

my $seqIO = new Bio::SeqIO (
  -file => $file,
  -format => 'fasta'
);

my $outputIO = new Bio::SeqIO (
  -file   => '>' . $output,
  -format => 'fasta'
);

while (my $seq = $seqIO->next_seq) {
  # Create a new sequence identifier based on a hex digest of the sequence
  # record using the SHA algorithm.
  my $sha = new Digest::SHA ();
  $sha->add ($seq->id);
  $sha->add ($seq->desc);
  $sha->add ($seq->seq);
  my $id = $sha->hexdigest;
  # Create a new sequence description based on the old sequence ID and
  # description.  
  my $desc = $seq->id;
  $desc .= ' ' . $seq->desc if (defined $seq->desc && $seq->desc ne '');
  # Output the renamed sequence.
  my $out = Bio::Seq->new (
    -id   => $id,
    -desc => $desc,
    -seq  => $seq->seq
  );
  $outputIO->write_seq ($out);
}
$outputIO->close;
$seqIO->close;

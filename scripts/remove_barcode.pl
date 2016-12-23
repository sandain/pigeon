#!/usr/bin/perl

use strict;
use warnings;

use Bio::Seq;
use Bio::SeqIO;


my $usage = "Usage: $0 <fasta file> <barcode sequence> <output file>\n";

die $usage if (@ARGV != 3);

my ($file, $barcode, $output) = @ARGV;

my $seqIO = new Bio::SeqIO (
  -file   => $file,
  -format => 'fasta'
);

my $outputIO = new Bio::SeqIO (
  -file   => '>' . $output,
  -format => 'fasta'
);

while (my $seq = $seqIO->next_seq) {
  my $sequence = $seq->seq;
  if ($sequence =~ /^$barcode(.*)/i) {
    $sequence = $1;
  }
  else {
    next;
  }
  my $out = Bio::Seq->new (
    -id   => $seq->id,
    -desc => $seq->desc,
    -seq  => $sequence
  );
  $outputIO->write_seq ($out);
}
$outputIO->close;
$seqIO->close;

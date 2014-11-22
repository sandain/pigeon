#!/usr/bin/perl

use strict;
use warnings;

use Bio::Seq;
use Bio::SeqIO;

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

my %sequences;
while (my $seq = $seqIO->next_seq) {
  if (defined $sequences{$seq->id} && $sequences{$seq->id}->seq ne $seq->id) {
    write "Duplicate ID found with different sequences: " .  $seq->id . "\n";
  }
  $sequences{$seq->id} = $seq;
}

foreach my $id (keys %sequences) {
  my $out = Bio::Seq->new (
    -id   => $id,
    -desc => $sequences{$id}->desc,
    -seq  => $sequences{$id}->seq
  );
  $outputIO->write_seq ($out);
}
$outputIO->close;
$seqIO->close;

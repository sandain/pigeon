#!/usr/bin/env perl

use strict;
use warnings;

use Bio::SeqIO;

my $usage = "Usage: $0 <Fasta File 1> <Fasta File 2> .. <Fasta File N>\n";

die $usage unless (@ARGV > 1);

my %sequences;
my @ids;
foreach my $gene (@ARGV) {
  my $seqIO = new Bio::SeqIO (
    -file   => '<' . $gene,
    -format => 'fasta'
  );
  my %ids = map {$_ => 1} @ids;
  while (my $seq = $seqIO->next_seq) {
    $sequences{$gene}{$seq->id} = $seq->seq;
    push @ids, $seq->id unless (defined $ids{$seq->id});
  }
  $seqIO->close ();
}

foreach my $id (@ids) {
  printf ">%s\n", $id;
  foreach my $gene (@ARGV) {
    die "Sequence not found: $gene $id\n" if (not defined $sequences{$gene}{$id});
    print $sequences{$gene}{$id};
  }
  print "\n";
}


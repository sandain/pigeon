#!/usr/bin/perl

use strict;
use warnings;

use Bio::Seq;
use Bio::SeqIO;


my $usage = "Usage: $0 <Input file> <Sequence Identifier>\n";

die $usage if (@ARGV != 2);

my ($inputFile, $identifier) = @ARGV;

my $seqIO = new Bio::SeqIO (
  -file   => '<' . $inputFile,
  -format => 'fasta'
);

while (my $seq = $seqIO->next_seq) {
  if ($seq->id =~ /$identifier/i) {
    print '>' . $seq->id;
    print ' ' . $seq->description if ($seq->description ne '');
    print "\n" . $seq->seq . "\n";
    last;
  }
}

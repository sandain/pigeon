#!/usr/bin/perl

use strict;
use warnings;

use Bio::Seq;
use Bio::SeqIO;

my $usage = "Usage: $0 <Input file> <Sequence Identifiers>\n";

die $usage unless (@ARGV >= 2);

my ($inputFile, @identifiers) = @ARGV;

die "File not found ($inputFile)\n" . $usage unless (-e $inputFile);

my $format = 'fasta';
$format = 'fastq' if ($inputFile =~ /fastq/i);

my %identifiers = map { my $id = $_; $id =~ s/\"//g; $id => 1 } @identifiers;

my $seqIO = new Bio::SeqIO (
  -file   => '<' . $inputFile,
  -format => $format
);

my %seqs;
while (my $seq = $seqIO->next_seq) {
  if (defined $identifiers{$seq->id}) {
    print '>' . $seq->id;
    print ' ' . $seq->description if ($seq->description ne '');
    print "\n" . $seq->seq . "\n";
  }
}
$seqIO->close;

#! /usr/bin/perl

use strict;
use warnings;

use Bio::SeqIO;


my ($clsFile, $fastaFile) = @ARGV;

my $usage = sprintf "Usage: %s <%s>\n", $0, join ('> <',
  'ESOM CLS file',
  'Fasta file'
);

if (not defined $clsFile) {
  print "Error, the ESOM CLS file was not provided.\n";
  print $usage;
  exit;
}
if (not defined $clsFile) {
  print "Error, the Fasta file was not provided.\n";
  print $usage;
  exit;
}

# Load the input sequence file.
my $fastaIO = new Bio::SeqIO (
  -file   => '<' . $fastaFile,
  -format => 'fasta'
);

my @sequences;

while (my $seq = $fastaIO->next_seq) {
  push @sequences, $seq;
}
$fastaIO->close;

open CLS, $clsFile or die "Error, unable to load the ESOM CLS file!\n";
while (my $line = <CLS>) {
  $line =~ s/[\r\n]//g;
  next if ($line =~ /^%/);
  my ($seqNum, $cluster) = split (/\t/, $line, 2);
  my $seq = $sequences[$seqNum];
  printf "%s\t%d\n", $seq->id, $cluster;
}
close CLS

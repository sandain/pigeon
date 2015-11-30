#! /usr/bin/perl

use strict;
use warnings;

use Bio::Seq;
use Bio::SeqIO;

my $usage = "Usage: $0 <input fasta> <output fasta> <HFS cutoff, optional> <LFS cutoff, optional>\n";

## Check command line argument.
die $usage if (@ARGV < 2);

my ($inputFile, $outputFile, $hfsCutoff, $lfsCutoff) = @ARGV;

$hfsCutoff = 0 if (not defined $hfsCutoff or $hfsCutoff eq '');
$lfsCutoff = ~0 if (not defined $lfsCutoff or $lfsCutoff eq '' or $hfsCutoff == 0);

# Make sure the input fasta file exists.
die "Input file not found!\n" if (! -e $inputFile);

# Create a SeqIO object for the input fasta file.
my $inputIO = new Bio::SeqIO (
  -file   => '<' . $inputFile,
  -format => 'fasta'
);

# Create a SeqIO object for the output fasta file.
my $outputIO = new Bio::SeqIO (
  -file   => '>' . $outputFile,
  -format => 'fasta'
);

# Load each genotype.
my (@genotypes, %genotypes);
while (my $seq = $inputIO->next_seq) {
  # Ignore any sequences with ambiguous bases.
  next if ($seq->seq =~ /[rywsmkbdhvnRYWSMKBDHVN]/);
  # Add the sequence to the list of genotypes.
  push @genotypes, $seq->seq if (not $seq->seq ~~ @genotypes);
  push @{$genotypes{$seq->seq}}, $seq;
}
# Close the SeqIO object.
$inputIO->close;

# Output the first representative sequence of each genotype.
my $hfsNum = 0;
my $lfsNum = 0;
foreach my $genotype (@genotypes) {
  my $id = 'null';
  my $size = @{$genotypes{$genotype}};
  my $seq = $genotypes{$genotype}[0]->seq;
  if ($size >= $hfsCutoff) {
    $id = sprintf "HFS%03d", $hfsNum;
    $hfsNum ++;
  }
  elsif ($size > $lfsCutoff) {
    $id = sprintf "LFS%03d", $lfsNum;
    $lfsNum ++;
  }
  next if ($id eq 'null');
  $outputIO->write_seq (
    new Bio::Seq (
      -id   => $id,
      -seq  => $seq,
      -desc => $size
    )
  );
}

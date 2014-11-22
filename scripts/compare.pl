#!/usr/bin/perl

use strict;
use warnings;

use Bio::SeqIO;

my $usage = "Usage: $0 <Reference file> <Barcode File> <Output file>\n";

die $usage if (@ARGV != 3);

my ($referenceFile, $barcodeFile, $outputFile) = @ARGV;


my $referenceIO = new Bio::SeqIO (
  -file   => '<' . $referenceFile,
  -format => 'fasta'
);

my $barcodeIO = new Bio::SeqIO (
  -file   => '<' . $barcodeFile,
  -format => 'fasta'
);

my @reference;
while (my $seq = $referenceIO->next_seq) {
  push @reference, $seq;
}
$referenceIO->close;


my (%data, %counts);
while (my $seq = $barcodeIO->next_seq) {
  my $barcodeSequence = lc $seq->seq;
  my $barcode = 'unknown';
  if ($seq->desc =~ /^([\w\-]+)::.*/) {
    $barcode = $1;
  }
  elsif ($seq->desc =~ /barcode_id=(\w+)/) {
    $barcode = $1;
  }
  next if ($barcode eq 'unknown');
  $counts{$barcode} ++;
  my $outputSeq = $seq;
  foreach my $ref (@reference) {
    my $refSequence = lc $ref->seq;
    if ($refSequence =~ /$barcodeSequence/) {
      my $id = $ref->id . '-' . $ref->desc;
      $data{$id}{total} ++;
      $data{$id}{$barcode} ++;
      last;
    }
  }
}
$barcodeIO->close;

my @ids = sort {
  my ($aGenotype, $bGenotype);
  my ($aSubtype, $bSubtype);
  my ($aNumber, $bNumber);
  my ($aHFS, $bHFS);
  if ($a =~ /(\w+)(\'?)(\d+)\-HFS(\d+)/) {
    $aGenotype = $1;
    $aSubtype = $2;
    $aNumber = $3;
    $aHFS = $4;
  }
  if ($b =~ /(\w+)(\'?)(\d+)\-HFS(\d+)/) {
    $bGenotype = $1;
    $bSubtype = $2;
    $bNumber = $3;
    $bHFS = $4;
  }
  if ($aGenotype eq $bGenotype) {
    if ($aSubtype eq $bSubtype) {    
      if ($aNumber == $bNumber) {
        return $aHFS <=> $bHFS;
      }
      else {
        return $aNumber <=> $bNumber;
      }
    }
    else {
        return $bSubtype cmp $aSubtype;
    }
  }
  else {
    return $aGenotype cmp $bGenotype;
  }
} keys %data;

my @barcodes = sort keys %counts;

open OUTPUT, '>' . $outputFile or die "Unable to write to output file: $!\n";
print OUTPUT "HFS\tTotal";
foreach my $barcode (@barcodes) {
  print OUTPUT "\t" . $barcode;
}
print OUTPUT "\n";
foreach my $id (@ids) {
  print OUTPUT $id . "\t" . $data{$id}{total};
  foreach my $barcode (@barcodes) {
    my $num = defined $data{$id}{$barcode} ? $data{$id}{$barcode} : 0;
    $num /= $counts{$barcode} if ($counts{$barcode} > 0);
    print OUTPUT "\t" . $num;
  }
  print OUTPUT "\n";
}
close OUTPUT;

#! /usr/bin/perl

require v5.10.1;

use strict;
use warnings;

use Bio::SeqIO;
use Data::Dumper;
use File::Basename;
use Pigeon::Statistics;

my $DEBUG = 0;

my $numThreads = 10;


# Grab command line input, return an error if not provided.
my $usage = "Usage: $0 <Ecotype Fasta> <Barcode CSV file> <Barcode List File>\n";
die $usage unless (@ARGV >= 2);
my ($fastaFile, $csvFile, $barcodeFile) = @ARGV;

my $statistics = new Pigeon::Statistics();

my %data;
my @names;
my %peNames;

# Grab the reference sequence.
my $fastaIO = new Bio::SeqIO (
  -file   => $fastaFile,
  -format => 'fasta'
);

while (my $seq = $fastaIO->next_seq) {
  push @{$peNames{$seq->id}}, $seq->id . '-' . $seq->desc;
}

# Sort the PE names.
my @pes = sort {
  my ($aGenotype, $bGenotype);
  my ($aNumber, $bNumber);
  if ($a =~ /([a-zA-Z\']+)(\d+)/) {
    $aGenotype = $1;
    $aNumber = $2;
  }
  if ($b =~ /([a-zA-Z\']+)(\d+)/) {
    $bGenotype = $1;
    $bNumber = $2;
  }
  if ($aGenotype eq $bGenotype) {
    return $aNumber <=> $bNumber;
  }
  else {
    return $aGenotype cmp $bGenotype;
  }
} keys %peNames;


# Load the barcode list file if it was provided.
my @barcodes;
if (defined $barcodeFile) {
  open (BARCODES, $barcodeFile) or die "Can't open file $barcodeFile: $!\n";
  while (my $line = <BARCODES>) {
    $line =~ s/[\r\n]//g;
    push @barcodes, $line;
  }
  close (BARCODES);
}

# Load the barcode CSV file.
my $lineno = 0;
open (CSV, $csvFile) or die "Can't open file $csvFile: $!\n";
while (my $line = <CSV>) {
  $line =~ s/[\r\n]//g;
  my @cols = split (/\t/, $line);
  # Extract the column names from the first line.
  if ($line =~ /^\t/) {
    @names = @cols[1..$#cols];
    next;
  }
  # Skip this row if the barcode was not requested.
  next if (@barcodes > 0 && not $cols[0] ~~ @barcodes);
  # Extract the count data for each column.
  for (my $i = 1; $i < @cols; $i ++) {
    $data{$names[$i-1]}[$lineno] = $cols[$i];
  }
  $lineno ++;
}
close (CSV);

# Add each hfs of a pe together.
my %peData;
foreach my $pe (@pes) {
  for (my $i = 0; $i < @{$peNames{$pe}}; $i ++) {
    for (my $j = 0; $j < @{$data{$peNames{$pe}[$i]}}; $j ++) {
      $peData{$pe}[$j] += $data{$peNames{$pe}[$i]}[$j];
    }
  }
}

# Sort the column names.
@names = sort {
  my ($aGenotype, $bGenotype);
  my ($aNumber, $bNumber);
  my ($aHFS, $bHFS);
  if ($a =~ /([a-zA-Z\']+)(\d+)\-HFS(\d+)/) {
    $aGenotype = $1;
    $aNumber = $2;
    $aHFS = $3;
  }
  if ($b =~ /([a-zA-Z\']+)(\d+)\-HFS(\d+)/) {
    $bGenotype = $1;
    $bNumber = $2;
    $bHFS = $3;
  }
  if ($aGenotype eq $bGenotype) {
    if ($aNumber == $bNumber) {
      return $aHFS <=> $bHFS;
    }
    else {
      return $aNumber <=> $bNumber;
    }
  }
  else {
    return $aGenotype cmp $bGenotype;
  }
} @names;

# Calculate the within-pe csv table.
my @withinPE;
for (my $i = 0; $i < @pes; $i ++) {
  my @gdata;
  for (my $j = 0; $j < @{$peNames{$pes[$i]}}; $j ++) {
    $gdata[$j] = $data{$peNames{$pes[$i]}[$j]};
  }
  print $pes[$i] . "\n" . Dumper (\@gdata) if ($DEBUG);
  my ($stat, $pvalue, $df) = $statistics->g_test (\@gdata);
  print "p-value: $pvalue\n" if ($DEBUG);
  $withinPE[$i] = $pvalue;
}

# Output the within-pe csv table.
my $withinpeCSV = '';
$withinpeCSV .= basename ($barcodeFile) . '_' if (defined $barcodeFile);
$withinpeCSV .= 'within-pe-' . basename ($csvFile);
open (WITHINPE, '>' . $withinpeCSV) or die "Can't open file $withinpeCSV: $!\n";
print WITHINPE "PE\tSize\tNo. HFS\tP-value\n";
for (my $i = 0; $i < @pes; $i ++) {
  my $size = 0;
  $size += $_ foreach (@{$peData{$pes[$i]}});
  my $num = @{$peNames{$pes[$i]}};
  print WITHINPE $pes[$i] . "\t";
  print WITHINPE $size . "\t";
  print WITHINPE $num . "\t";
  printf WITHINPE "%.2f", $withinPE[$i] if ($withinPE[$i] ne "");
  print WITHINPE "\n";
}
close (WITHINPE);

# Calculate the between-pe csv table.
my @betweenPE;
for (my $i = 0; $i < @pes; $i ++) {
  for (my $j = 0; $j <= $i; $j ++) {
    my @gdata = ($peData{$pes[$i]}, $peData{$pes[$j]});
    print Dumper (\@gdata) if ($DEBUG);
    my ($stat, $pvalue, $df) = $statistics->g_test (\@gdata);
    print "p-value: $pvalue\n" if ($DEBUG);
    $betweenPE[$i][$j] = $pvalue;
  }
}

# Output the between-pe csv table.
my $peCSV = '';
$peCSV .= basename ($barcodeFile) . '_' if (defined $barcodeFile);
$peCSV .= 'between-pe-' . basename ($csvFile);
open (BETWEENPE, '>' . $peCSV) or die  "Can't open file $peCSV: $!\n";
print BETWEENPE "PE\tSize\tNo. HFS";
for (my $i = 0; $i < @pes; $i ++) {
  print BETWEENPE "\t" . $pes[$i];
}
print BETWEENPE "\n";
for (my $i = 0; $i < @pes; $i ++) {
  my $size = 0;
  $size += $_ foreach (@{$peData{$pes[$i]}});
  my $num = @{$peNames{$pes[$i]}};
  printf BETWEENPE "%s\t%d\t%d", $pes[$i], $size, $num;
  for (my $j = 0; $j <= $i; $j ++) {
    printf BETWEENPE "\t%.2f", $betweenPE[$i][$j];
  }
  print BETWEENPE "\n";
}
close (BETWEENPE);

# Calculate the between-hfs csv table.
my @betweenHFS;
for (my $i = 0; $i < @names; $i ++) {
  for (my $j = 0; $j <= $i; $j ++) {
    my @gdata = ($data{$names[$i]}, $data{$names[$j]});
    print Dumper (\@gdata) if ($DEBUG);
    my ($stat, $pvalue, $df) = $statistics->g_test (\@gdata);
    print "p-value: $pvalue\n" if ($DEBUG);
    $betweenHFS[$i][$j] = $pvalue;
  }
}

# Output the between-hfs csv table.
my $hfsCSV = '';
$hfsCSV .= basename ($barcodeFile) . '_' if (defined $barcodeFile);
$hfsCSV .= 'between-hfs-' . basename ($csvFile);
open (BETWEENHFS, '>' . $hfsCSV) or die "Can't open file $hfsCSV: $!\n";
print BETWEENHFS "HFS\tSize";
for (my $i = 0; $i < @names; $i ++) {
  print BETWEENHFS "\t" . $names[$i];
}
print BETWEENHFS "\n";
for (my $i = 0; $i < @names; $i ++) {
  my $size = 0;
  $size += $_ foreach (@{$data{$names[$i]}});
  printf BETWEENHFS "%s\t%d", $names[$i], $size;
  for (my $j = 0; $j <= $i; $j ++) {
    printf BETWEENHFS "\t%.2f", $betweenHFS[$i][$j];
  }
  print BETWEENHFS "\n";
}
close (BETWEENHFS);

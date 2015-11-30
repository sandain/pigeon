#! /usr/bin/perl

use strict;
use warnings;

use Bio::Seq;
use Bio::SeqIO;

my $usage = "Usage: $0 <Database Fasta> <HFS Fasta> <Output CSV>\n";

## Check command line argument.
die $usage if (@ARGV != 3);

my ($dbFile, $hfsFile, $outputFile) = @ARGV;

# Load the fasta files.
my $dbIO = new Bio::SeqIO (
  -file   => '<' . $dbFile,
  -format => 'fasta'
);
my $hfsIO = new Bio::SeqIO (
  -file   => '<' . $hfsFile,
  -format => 'fasta'
);

my @barcodes;
my @hfs;
my %count;

# Load the HFS.
while (my $seq = $hfsIO->next_seq) {
  push @hfs, $seq;
  $count{$seq->seq} = {};
}

# Count the HFS.
while (my $seq = $dbIO->next_seq) {
  next if (not defined $count{$seq->seq});
  # Look for the barcode.
  my $barcode = 'unknown';
  if ($seq->desc =~ /barcode_id=([\w\d]+)/) {
    $barcode = $1;
  }
  elsif ($seq->desc =~ /barcode=([\w\d]+)/) {
    $barcode = $1;
  }
  elsif ($seq->desc =~ /^[a-zA-Z_0-9-]+::(.*)/) {
    $barcode = $1;
  }
print $seq->id . "\t" . $barcode . "\n";

  push @barcodes, $barcode if (not $barcode ~~ @barcodes);
  $count{$seq->seq}{$barcode} = 0 if (not defined $count{$seq->seq}{$barcode});
  $count{$seq->seq}{$barcode} ++;

}

# Close the fasta files.
$hfsIO->close;
$dbIO->close;

# Open the output file with write access.
open OUTPUT, '>' . $outputFile or die "Unable to write to output file: $!\n";
foreach my $seq (@hfs) {
  print OUTPUT "\t" . $seq->id;  
}
print OUTPUT "\n";
foreach my $barcode (@barcodes) {
  print OUTPUT $barcode;
  foreach my $seq (@hfs) {
    $count{$seq->seq}{$barcode} = 0 if (not defined $count{$seq->seq}{$barcode});
    print OUTPUT "\t" . $count{$seq->seq}{$barcode};
  }
  print OUTPUT "\n";
}

# Close the output file.
close OUTPUT;


#! /usr/bin/perl

use strict;
use warnings;

use Bio::Seq;
use Bio::SeqIO;

my $with_replacement = 0;

## Check command line argument.
if ( @ARGV != 2 ) {
  print "Usage: $0 <fasta> <number>\n";
  exit 1;
}

my ($fastaFile, $number) = @ARGV;

# Make sure the input fasta file exists.
if (! -e $fastaFile) {
  print "Input file not found!\n";
  exit 1;
}

# Create a SeqIO object for the input fasta file.
my $fastaIO = new Bio::SeqIO (
  -file   => '<' . $fastaFile,
  -format => 'fasta'
);

# Add each sequence in the fasta file to a hash with the key being the sequence
# identifier.  Preserve the order of sequences by storing the sequence
# indentifiers in an array.
my @ids;
my %sequences;
while (my $seq = $fastaIO->next_seq) {
  push @ids, $seq->id;
  $sequences{$seq->id} = $seq;
}

# Close the SeqIO object.
$fastaIO->close;

# Output the necesary number of sequences.
for (my $i = 0; $i < $number; $i ++) {
  # Choose a random sequence.
  my $index = int(rand(scalar @ids));
  my $seq = $sequences{$ids[$index]};
  # Remove the sequence from further consideration if needed.
  if (not $with_replacement) {
    splice (@ids, $index, 1);
  }
  # Output the sequence.
  print ">" . $seq->id;
  print ' ' . $seq->description if (defined $seq->description);
  print "\n";
  print $seq->seq . "\n";
}

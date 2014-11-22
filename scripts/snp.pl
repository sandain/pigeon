#! /usr/bin/perl

use strict;
use warnings;

use Pigeon::Fasta;
use Pigeon::Graphics;
use File::Basename;

my ($minHeight, $minWidth) = (600, 1300);

my $usage = "Usage: $0 <Fasta File>\n";


if (scalar @ARGV == 0) {
  print "Error, a fasta file was not provided.\n";
  print $usage;
  exit;
}

my @files = @ARGV;

# Create Pigeon::Data and Pigeon::Graphics objects.
my $snp_data = new Pigeon::Data (
  type => 'text'
);
my $snp_graphics = new Pigeon::Graphics(pigeon_data => $snp_data);
# Create the graphics.
foreach my $file (@files) {
  my $fasta = new Pigeon::Fasta (fileName => $file);
  # Figure out the name of the file.
  my ($name, $directory, $extension) = fileparse($file, qr/\.[^.]*/);
  # Calculate the height and width of the graphic to make based on the number
  # and length of the sequences in the fasta file.
  my $height = 25 * $fasta->size() + 100;
  my $width = 3 * $fasta->maxLength() + 250;
  # Make sure the height and width are at least the minimum size.
  $height = $minHeight if ($height < $minHeight);
  $width = $minWidth if ($width < $minWidth);
  # Generate the graphic.
  $snp_graphics->snp_location_graph (
    file_name        => $name . '.snp.gif',
    fasta            => $fasta,
    height           => $height,
    width            => $width
  );
}

#! /usr/bin/perl

use strict;
use warnings;

use Pigeon::Fasta;
use Pigeon::Graphics;

my $output_directory = 'output';

# SNP fasta files.
my @files = (
  # MLSA 5 SynA
  'MLSA5SynAPE10DVST3.fas',
  'MLSA5SynAPE13DVST1.fas',
  'MLSA5SynAPE8DVST2.fas',
  'MLSA5SynAPE9DVST5.fas',
  # MLSA 7 SynA
  'MLSA7SynADV1slvPEVs.fas',
  'MLSA7SynADV5slvPEVs.fas',
  'MLSA7SynADV6slvPEVs.fas',
  'MLSA7SynADV7PEVs.fas',
   # MLSA 4 SynB
  'MLSA4SynBPE1_2DV1.fas',
  'MLSA4SynBPE6_7DV6.fas',
  'MLSA4SynBPE15_16DV5.fas',
  'MLSA4SynBPE16DVST5slvsPEVs.fas',
  'MLSA4SynBPE18DV4.fas',
  'MLSA4SynBPE22DV2.fas',
);

# Gene locations.
my $gene_locations = {
  'MLSA5SynA' => {
    'aroA'     => [   0,  612],
    'chp'      => [ 613, 1203],
    'lepB'     => [1204, 1665],
    'pk'       => [1666, 2301],
    'rbsK'     => [2302, 2803],
    'combined' => [0, 614, 1205, 1666, 2302, 2803]
  },
  'MLSA7SynA' => {
    'rbsK'     => [   0,  581],
    'pk'       => [ 582, 1235],
    'hisF'     => [1236, 1664],
    'lepB'     => [1665, 2126],
    'chp'      => [2127, 2804],
    'aroA'     => [2805, 3461],
    'dnaG'     => [3462, 4008],
    'combined' => [0, 582, 1236, 1665, 2127, 2805, 3462, 4008]
  },
  'MLSA4SynB' => {
    'aroA'     => [   0,  590],
    'rbsK'     => [ 550, 1084],
    'pcrA'     => [1085, 1714],
    '16S'      => [1715, 2448],
    'combined' => [0, 550, 1085, 1715, 2448]
  }
};

my $labels = {
  'MLSA5SynA' => {
    'aroA'     => ['aroA'],
    'chp'      => ['chp'],
    'lepB'     => ['lepB'],
    'pk'       => ['pk'],
    'rbsK'     => ['rbsK'],
    'combined' => ['aroA', 'chp', 'lepB', 'pk', 'rbsK']
  },
  'MLSA7SynA' => {
    'rbsK'     => ['rbsK'],
    'pk'       => ['pk'],
    'hisF'     => ['hisF'],
    'lepB'     => ['lepB'],
    'chp'      => ['chp'],
    'aroA'     => ['aroA'],
    'dnaG'     => ['dnaG'],
    'combined' => ['rbsK', 'pk', 'hisF', 'lepB', 'chp', 'aroA', 'dnaG']
  },
  'MLSA4SynB' => {
    'aroA'     => ['aroA'],
    'rbsK'     => ['rbsK'],
    'pcrA'     => ['pcrA'],
    '16S'      => ['16S/ITS'],
    'combined' => ['aroA', 'rbsK', 'pcrA', '16S/ITS']
  }
};

# Create Pigeon::Data and Pigeon::Graphics objects.
my $snp_data = new Pigeon::Data ();
my $snp_graphics = new Pigeon::Graphics(pigeon_data => $snp_data);

# Create the graphics.
foreach my $file (@files) {
  my $fasta = new Pigeon::Fasta (fileName => $file);
  my ($name, $experiment);
  if ($file =~ /((MLSA\d+Syn[AB]).*)\.fas/) {
    $name = $1;
    $experiment = $2;
  }
  foreach my $gene (keys %{$gene_locations->{$experiment}}) {
    $snp_graphics->snp_location_graph (
      file_name        => $output_directory . '/' . $experiment . '/' . $name .'_' . $gene . '.gif',
      width            => 800,
      height           => 350,
      fasta            => $fasta,
      normal_font      => '/usr/share/fonts/truetype/freefont/FreeMonoBold.ttf',
      title_font       => '/usr/share/fonts/truetype/freefont/FreeMonoBold.ttf',
      normal_font_size => 12,
      title_font_size  => 12,
      legend           => ['Sequences from Ecotype Simulation', 'Sequences from Both', 'Sequences from eBURST'],
      pixel_size       => [2, 2, 2],
      categories       => ['pev', 'both', 'slv'],
      colors           => ['red', 'purple', 'blue'],
      start            => $gene_locations->{$experiment}{$gene}->[0],
      end              => $gene_locations->{$experiment}{$gene}->[@{$gene_locations->{$experiment}{$gene}} - 1],
      x_labels         => $labels->{$experiment}{$gene},
      x_label_location => $gene_locations->{$experiment}{$gene},
      x_long_tics      => 1
    );
  }
}

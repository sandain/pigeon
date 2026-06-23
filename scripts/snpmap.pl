#!/bin/env perl

use strict;
use warnings;

use Bio::SeqIO;
use Number::Format 'format_number';

my $usage = "Usage: $0 <Fasta or Fastq Input File> <Output SVG File> <Title, optional>\n";

my @colors = ('#648FFF', '#785EF0', '#DC267F', '#FE6100', '#FFB000', '#AAAAAA');

my %codon_table = (
  'TTT' => 'Phe',   'TCT' => 'Ser',   'TAT' => 'Tyr',   'TGT' => 'Cys',
  'TTC' => 'Phe',   'TCC' => 'Ser',   'TAC' => 'Tyr',   'TGC' => 'Cys',
  'TTA' => 'Leu',   'TCA' => 'Ser',   'TAA' => 'Ochre', 'TGA' => 'Opal',
  'TTG' => 'Leu',   'TCG' => 'Ser',   'TAG' => 'Amber', 'TGG' => 'Trp',
  'CTT' => 'Leu',   'CCT' => 'Pro',   'CAT' => 'His',   'CGT' => 'Arg',
  'CTC' => 'Leu',   'CCC' => 'Pro',   'CAC' => 'His',   'CGC' => 'Arg',
  'CTA' => 'Leu',   'CCA' => 'Pro',   'CAA' => 'Gln',   'CGA' => 'Arg',
  'CTG' => 'Leu',   'CCG' => 'Pro',   'CAG' => 'Gln',   'CGG' => 'Arg',
  'ATT' => 'Ile',   'ACT' => 'Thr',   'AAT' => 'Asn',   'AGT' => 'Ser',
  'ATC' => 'Ile',   'ACC' => 'Thr',   'AAC' => 'Asn',   'AGC' => 'Ser',
  'ATA' => 'Ile',   'ACA' => 'Thr',   'AAA' => 'Lys',   'AGA' => 'Arg',
  'ATG' => 'Met',   'ACG' => 'Thr',   'AAG' => 'Lys',   'AGG' => 'Arg',
  'GTT' => 'Val',   'GCT' => 'Ala',   'GAT' => 'Asp',   'GGT' => 'Gly',
  'GTC' => 'Val',   'GCC' => 'Ala',   'GAC' => 'Asp',   'GGC' => 'Gly',
  'GTA' => 'Val',   'GCA' => 'Ala',   'GAA' => 'Glu',   'GGA' => 'Gly',
  'GTG' => 'Val',   'GCG' => 'Ala',   'GAG' => 'Glu',   'GGG' => 'Gly'
);

my %dna_colors = (
  'synonymous'    => $colors[0],
  'nonsynonymous' => $colors[2],
  'unknown'       => $colors[5]
);

my %aa_colors = (
  'A' => $colors[0], # Nonpolar
  'G' => $colors[0], # Nonpolar
  'I' => $colors[0], # Nonpolar
  'L' => $colors[0], # Nonpolar
  'M' => $colors[0], # Nonpolar
  'P' => $colors[0], # Nonpolar
  'V' => $colors[0], # Nonpolar
  'C' => $colors[1], # Polar
  'N' => $colors[1], # Polar
  'Q' => $colors[1], # Polar
  'S' => $colors[1], # Polar
  'T' => $colors[1], # Polar
  'D' => $colors[2], # Acidic
  'E' => $colors[2], # Acidic
  'H' => $colors[3], # Basic
  'K' => $colors[3], # Basic
  'R' => $colors[3], # Basic
  'F' => $colors[4], # Aromatic
  'W' => $colors[4], # Aromatic
  'Y' => $colors[4]  # Aromatic
);

die $usage unless (@ARGV >= 2);

my ($input, $output, $title) = @ARGV;

my $format = 'fasta';
$format = 'fastq' if ($input =~ /fastq/i);

my $seqIO = new Bio::SeqIO (
  -file   => '<' . $input,
  -format => $format
);

die "File not found!\n" . $usage unless (-e $input);

my @seqs;
my $ref_id;
my $ref_seq;
my $alphabet;
my $max_id_length = 0;
while (my $seq = $seqIO->next_seq) {
  unless (defined $ref_seq) {
    $ref_id = $seq->id;
    $ref_seq = $seq->seq;
    $alphabet = $seq->alphabet;
    next;
  }
  push @seqs, $seq;
  my $id_length = length ($seq->id);
  $max_id_length = $id_length if ($id_length > $max_id_length);
}
$seqIO->close;

die "Reference sequence not defined!\n" unless defined ($ref_seq);
die "Insufficent sequences!\n" unless (@seqs > 0);

# Map the SNPs for each sequence.
my %snps;
for (my $i = 0; $i < @seqs; $i ++) {
  my $seq = $seqs[$i];
  $snps{$seq->id} = [];
  for (my $j = 0; $j < length $ref_seq; $j ++) {
    my $ref_char = uc substr $ref_seq, $j, 1;
    my $char = uc substr $seq->seq, $j, 1;
    push @{$snps{$seq->id}}, $j unless ($ref_char eq $char);
  }
}

# Calculate height and width of image.
my $height = 75 + 25 * @seqs;
my $width = 1500;

# Calculate the plot area in the image.
my $xmin = 9 * $max_id_length + 10;
my $xmax = $width - 10;
my $ymin = 50;

# Increase the size of the image and the location of the plot area if the title is defined.
if (defined $title) {
  $height += 50;
  $ymin += 50;
}

# Plot the SNPs to SVG format.
open my $svg, '>:utf8', $output or die "Unable to write to output file!";
printf $svg "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n";
printf $svg "<svg version=\"1.1\" baseProfile=\"tiny\" height=\"%dpx\" width=\"%dpx\" xmlns=\"http://www.w3.org/2000/svg\" font-family=\"Liberation Sans, sans-serif\">\n", $height, $width;
printf $svg "<path d=\"M 0,0 L %d,0 %d,%d 0,%d Z\" fill=\"#ffffff\"/>\n", $width, $width, $height, $height;
printf $svg "<text x=\"%d\" y=\"%d\" text-anchor=\"middle\" font-size=\"25px\" font-weight=\"bold\">%s</text>", $width / 2, 30, $title if (defined $title);
printf $svg "<path d=\"M %d,%d L %d,%d\" stroke=\"#000000\"/>\n", $xmin, $ymin - 20, $xmax, $ymin - 20;
printf $svg "<path d=\"M %d,%d L %d,%d\" stroke=\"#000000\"/>\n", $xmin, $ymin - 25, $xmin, $ymin - 15;
printf $svg "<path d=\"M %d,%d L %d,%d\" stroke=\"#000000\"/>\n", $xmax, $ymin - 25, $xmax, $ymin - 15;
printf $svg "<path d=\"M %d,%d L %d,%d\" stroke=\"#000000\"/>\n", 0.25 * ($xmax - $xmin) + $xmin, $ymin - 25, 0.25 * ($xmax - $xmin) + $xmin, $ymin - 15;
printf $svg "<path d=\"M %d,%d L %d,%d\" stroke=\"#000000\"/>\n", 0.50 * ($xmax - $xmin) + $xmin, $ymin - 25, 0.50 * ($xmax - $xmin) + $xmin, $ymin - 15;
printf $svg "<path d=\"M %d,%d L %d,%d\" stroke=\"#000000\"/>\n", 0.75 * ($xmax - $xmin) + $xmin, $ymin - 25, 0.75 * ($xmax - $xmin) + $xmin, $ymin - 15;
printf $svg "<text x=\"%d\" y=\"%d\" dominant-baseline=\"middle\" text-anchor=\"end\" font-size=\"15px\">%s</text>\n", $xmin - 10, $ymin - 25, $ref_id;
printf $svg "<text x=\"%d\" y=\"%d\" text-anchor=\"start\" font-size=\"15px\">%s</text>\n", $xmin, $ymin - 25, 0;
printf $svg "<text x=\"%d\" y=\"%d\" text-anchor=\"end\" font-size=\"15px\">%s</text>\n", $xmax, $ymin - 25, format_number length $ref_seq;
my $unknown = 0;
for (my $i = 0; $i < @seqs; $i ++) {
  my $id = $seqs[$i]->id;
  my $y = $ymin + 25 * $i;
  printf $svg "<text x=\"%d\" y=\"%d\" dominant-baseline=\"middle\" text-anchor=\"end\" font-size=\"15px\">%s</text>\n", $xmin - 10, $y, $id;
  printf $svg "<path d=\"M %d,%d %d,%d\" stroke=\"#777777\"/>\n", $xmin, $y, $width - 10, $y;
  foreach my $snp (@{$snps{$id}}) {
    my $cx = $xmin + ($snp * ($xmax - $xmin)) / length $ref_seq;
    my $color;
    if ($alphabet eq 'dna') {
      my $codon = uc substr $seqs[$i]->seq, codon_start($snp), 3;
      my $ref_codon = uc substr $ref_seq, codon_start($snp), 3;
      if (defined $codon_table{$ref_codon} and defined $codon_table{$codon}) {
        $color = $dna_colors{'synonymous'};
        $color = $dna_colors{'nonsynonymous'} unless ($codon_table{$ref_codon} eq $codon_table{$codon});
      }
      else {
        $color = $dna_colors{'unknown'};
        $unknown++;
      }
    }
    else {
      my $aa = uc substr $seqs[$i]->seq, $snp, 1;
      $color = $aa_colors{$aa};
    }

    die "no color" unless (defined $color);

    printf $svg "<circle cx=\"%d\" cy=\"%d\" r=\"4\" fill=\"%s\"/>\n", $cx, $y, $color;
  }
}
# Plot the legend.
my $ylegend = $ymin + 25 * (@seqs + 0.5);
if ($alphabet eq 'dna') {
  printf $svg "<circle cx=\"%d\" cy=\"%d\" r=\"5\" fill=\"%s\"/>\n", $xmin + 0.25 * ($xmax - $xmin), $ylegend, $dna_colors{'synonymous'};
  printf $svg "<text x=\"%d\" y=\"%d\" dominant-baseline=\"middle\">Synonymous Mutation</text>\n", $xmin + 0.25 * ($xmax - $xmin) + 10, $ylegend;
  printf $svg "<circle cx=\"%d\" cy=\"%d\" r=\"5\" fill=\"%s\"/>\n", $xmin + 0.50 * ($xmax - $xmin), $ylegend, $dna_colors{'nonsynonymous'};
  printf $svg "<text x=\"%d\" y=\"%d\" dominant-baseline=\"middle\">Nonsynonymous Mutation</text>\n", $xmin + 0.50 * ($xmax - $xmin) + 10, $ylegend;
  if ($unknown > 0) {
    printf $svg "<circle cx=\"%d\" cy=\"%d\" r=\"5\" fill=\"%s\"/>\n", $xmin + 0.75 * ($xmax - $xmin), $ylegend, $dna_colors{'unknown'};
    printf $svg "<text x=\"%d\" y=\"%d\" dominant-baseline=\"middle\">Unknown</text>\n", $xmin + 0.75 * ($xmax - $xmin) + 10, $ylegend;
  }
}
else {
  printf $svg "<circle cx=\"%d\" cy=\"%d\" r=\"5\" fill=\"%s\"/>\n", $xmin + 0.5 * ($xmax - $xmin) - 400, $ylegend, $aa_colors{'F'};
  printf $svg "<text x=\"%d\" y=\"%d\" dominant-baseline=\"middle\">Aromatic (F,W,Y)</text>\n", $xmin + 0.5 * ($xmax - $xmin) - 390, $ylegend;

  printf $svg "<circle cx=\"%d\" cy=\"%d\" r=\"5\" fill=\"%s\"/>\n", $xmin + 0.5 * ($xmax - $xmin) - 220, $ylegend, $aa_colors{'D'};
  printf $svg "<text x=\"%d\" y=\"%d\" dominant-baseline=\"middle\">Acidic (D,E)</text>\n", $xmin + 0.5 * ($xmax - $xmin) - 210, $ylegend;

  printf $svg "<circle cx=\"%d\" cy=\"%d\" r=\"5\" fill=\"%s\"/>\n", $xmin + 0.5 * ($xmax - $xmin) - 80, $ylegend, $aa_colors{'R'};
  printf $svg "<text x=\"%d\" y=\"%d\" dominant-baseline=\"middle\">Basic (H,K,R)</text>\n", $xmin + 0.5 * ($xmax - $xmin) - 70, $ylegend;


  printf $svg "<circle cx=\"%d\" cy=\"%d\" r=\"5\" fill=\"%s\"/>\n", $xmin + 0.5 * ($xmax - $xmin) + 60, $ylegend, $aa_colors{'A'};
  printf $svg "<text x=\"%d\" y=\"%d\" dominant-baseline=\"middle\">Nonpolar (A,G,I,L,M,P,V)</text>\n", $xmin + 0.5 * ($xmax - $xmin) + 70, $ylegend;

  printf $svg "<circle cx=\"%d\" cy=\"%d\" r=\"5\" fill=\"%s\"/>\n", $xmin + 0.5 * ($xmax - $xmin) + 280, $ylegend, $aa_colors{'C'};
  printf $svg "<text x=\"%d\" y=\"%d\" dominant-baseline=\"middle\">Polar (C,N,Q,S,T)</text>\n", $xmin + 0.5 * ($xmax - $xmin) + 290, $ylegend;


}
printf $svg "</svg>\n";
close $svg;

sub codon_start {
  my $snp = shift;
  return $snp - 2 if (($snp + 1) % 3 == 0);
  return $snp - 1 if (($snp + 1) % 3 == 2);
  return $snp;
}


#! /usr/bin/perl

use strict;
use warnings;

use Pigeon::Data;
use Pigeon::Fasta;
use Pigeon::Graphics;
use Pigeon::Text;
use Pigeon::Tools qw(:all);

###################################################################################################
## Data files
###################################################################################################
my $output_directory = 'output';

my $bac_metagenome_file = 'randomBACends.fa';
my $cyano_metagenome_file = 'cyanoBACends.fa';

my $bac_metablast_file = 'randomBACends_vs_20Bin.blastn.parsed';
my $cyano_metablast_file = 'cyanoBACends_vs_SynAB.blastn.parsed';

my $clusters_metablast_file = 'randomBACends_vs_assembly_clusters.blastn.parsed';

###################################################################################################

###################################################################################################
## Global Variables
###################################################################################################

my $alpha = 0.05;

my $bac_data = new Pigeon::Data (
  type            => 'text', 
  metablast_file  => $bac_metablast_file, 
  metagenome_file => $bac_metagenome_file
);

my $cyano_data = new Pigeon::Data (
  type            => 'text', 
  metablast_file  => $cyano_metablast_file, 
  metagenome_file => $cyano_metagenome_file
);

my $clusters_data = new Pigeon::Data (
  type            => 'text',
  metablast_file  => $clusters_metablast_file,
  metagenome_file => $bac_metagenome_file
);

my $bac_graphics = new Pigeon::Graphics (pigeon_data => $bac_data);
my $cyano_graphics = new Pigeon::Graphics (pigeon_data => $cyano_data);
my $clusters_graphics = new Pigeon::Graphics (pigeon_data => $clusters_data);


my $bac_text = new Pigeon::Text (pigeon_data => $bac_data);
my $cyano_text = new Pigeon::Text (pigeon_data => $cyano_data);

my $normal_font = '/usr/share/fonts/truetype/ttf-bitstream-vera/Vera.ttf';
my $title_font = '/usr/share/fonts/truetype/ttf-bitstream-vera/VeraBd.ttf';

my @metagenomes = (
  "mslow",
  "mshigh"
);

my @bac_bins = (
  "synechococcus_sp._os-type_a_strain",
  "synechococcus_sp._os-type_b'_strain",
  "thermosynechococcus_elongatus_bp-1",
  "roseiflexus_sp._rs1",
  "chloroflexus_sp._396-1",
  "chloracidobacterium_thermophilum",
  "chloroherpeton_thalassium",
  "thermomicrobium_roseum",
  "thermus_thermophilus_hb8",
  "herpetosiphon_aurantiacus_atcc_23779",
  "acidobacteria_bacterium_ellin345",
  "thermoanaerobacter_ethanolicus_atcc_33223",
  "carboxydothermus_hydrogenoformans_z-2901",
  "bacteroides_vulgatus_atcc_8482",
  "thermodesulfovibrio_yellowstonii",
  "thermodesulfobacterium_commune_dsm_2178",
  "rhodoferax_ferrireducens_t118",
  "methanothermobacter_thermautotrophicus_str._delta_h",
  "aquifex_aeolicus_vf5",
  "thermoproteus_neutrophilus_v24sta",
);

my @cyano_bins = (
  "synechococcus_sp._os-type_a_strain",
  "synechococcus_sp._os-type_b'_strain",
);

my @clusterBins;
for (my $i = 1; $i < 9; $i ++) {
  push @clusterBins, 'cluster' . $i;
}

my $length = {
  "synechococcus_sp._os-type_a_strain"                  => 2932766,
  "synechococcus_sp._os-type_b'_strain"                 => 3046682,
  "thermosynechococcus_elongatus_bp-1"                  => 2588177,
  "roseiflexus_sp._rs1"                                 => 5801599,
  "chloroflexus_sp._396-1"                              => 264402,
  "chloracidobacterium_thermophilum"                    => 2683362,
  "chloroherpeton_thalassium"                           => 1881424,
  "thermomicrobium_roseum"                              => 2002246,
  "thermus_thermophilus_hb8"                            => 1849565,
  "herpetosiphon_aurantiacus_atcc_23779"                => 284345,
  "acidobacteria_bacterium_ellin345"                    => 5649312,
  "thermoanaerobacter_ethanolicus_atcc_33223"           => 307954,
  "carboxydothermus_hydrogenoformans_z-2901"            => 2397998,
  "bacteroides_vulgatus_atcc_8482"                      => 5161500,
  "thermodesulfovibrio_yellowstonii"                    => 2003217,
  "thermodesulfobacterium_commune_dsm_2178"             => 1785651,
  "rhodoferax_ferrireducens_t118"                       => 4710094,
  "methanothermobacter_thermautotrophicus_str._delta_h" => 1741839,
  "aquifex_aeolicus_vf5"                                => 1549995,
  "thermoproteus_neutrophilus_v24sta"                   => 612693
};

my $rrna_16s = {
  "synechococcus_sp._os-type_a_strain"                  => [1110781, 2310964],
  "synechococcus_sp._os-type_b'_strain"                 => [1448019, 2053259],
};

# Calculate the location of the tics.
my ($tic_locations, $tic_labels);
foreach my $bin (keys %{$length}) {
  # Create the tic_locations for the current bin.
  $tic_locations->{$bin} = [
    0, 
    $length->{$bin}
  ];
  # Add 16S locations to the tic_locations, if defined for the current bin.
  if (defined $rrna_16s->{$bin}) {
    splice @{$tic_locations->{$bin}}, 1, 0, @{$rrna_16s->{$bin}};
  }
  # Create the tic_labels for the current bin.
  foreach my $tic (@{$tic_locations->{$bin}}) {
    push @{$tic_labels->{$bin}}, round ($tic / 1000) . ' kb';
  }
}

###################################################################################################


###################################################################################################
## Produces all of the Rank Abundance Graphics
###################################################################################################
sub produce_rank_abundance_graphs {
  my @categories = ('paired_nonsyntenous', 'paired_syntenous');
  my @colors = ('blue', 'red');
  foreach my $metagenome (@metagenomes) {
    $bac_graphics->rank_abundance_graph (
      bins            => [@bac_bins, 'null'],
      metagenomes     => [$metagenome],
      sizes           => ['total'],
      extracted       => ['total'],
      layers          => ['total'],
      max_evalue      => '1e-10',
      min_length      => '100',
      file_name       => $output_directory . "/bac/" . $metagenome . ".gif",
      title           => $bac_data->long_description(bin => $metagenome),
      title_justify   => 'left',
      legend_location => 'bottom'
    );
    $cyano_graphics->rank_abundance_graph (
      bins            => [@cyano_bins, 'null'],
      metagenomes     => [$metagenome],
      sizes           => ['total'],
      extracted       => ['total'],
      layers          => ['total'],
      max_evalue      => '1e-10',
      min_length      => '100',
      file_name       => $output_directory . "/cyano/" . $metagenome . ".gif",
      title           => $cyano_data->long_description(bin => $metagenome),
      title_justify   => 'left',
      legend_location => 'bottom',
    );
  }

  $clusters_graphics->rank_abundance_graph (
      bins            => [@clusterBins, 'null'],
      metagenomes     => ['total'],
      sizes           => ['total'],
      extracted       => ['total'],
      layers          => ['total'],
      max_evalue      => '1e-10',
      min_length      => '100',
      file_name       => $output_directory . "/clusters/rank_abundance.gif",
      title           => 'Random BAC ends vs Clusters',
      title_justify   => 'left',
      legend_location => 'bottom',
  );
}
###################################################################################################

###################################################################################################
## Produces all of the Hit Quality Graphics
###################################################################################################
sub produce_hit_quality_graphs {
  my @categories = ('unpaired', 'paired_nonsyntenous', 'paired_syntenous');
  my @colors = ('green', 'blue', 'red');
  foreach my $metagenome (@metagenomes) {
    foreach my $bin (@bac_bins) {
      $bac_graphics->hit_quality_graph (
        bins            => [$bin], 
        metagenomes     => [$metagenome],
        sizes           => ['total'],
        extracted       => ['total'],
        layers          => ['total'],
        max_evalue      => '1e-10',
        min_length      => '100',
        categories      => \@categories,
        colors          => \@colors,
        low             => 50,
        high            => 100,
        file_name       => $output_directory . '/bac/hit_quality/' . $metagenome . '/' . $bin . '.gif',
        title           => $bac_data->long_description(bin => $bin),
        title_justify   => 'center',
        legend_location => 'none'
      );
    }
    foreach my $bin (@cyano_bins) {
      $cyano_graphics->hit_quality_graph (
        bins            => [$bin], 
        metagenomes     => [$metagenome],
        sizes           => ['total'],
        extracted       => ['total'],
        layers          => ['total'],
        max_evalue      => '1e-10',
        min_length      => '100',
        categories      => \@categories,
        colors          => \@colors,
        low             => 50,
        high            => 100,
        file_name       => $output_directory . '/cyano/hit_quality/' . $metagenome . '/' . $bin . '.gif',
        title           => $cyano_data->long_description(bin => $bin),
        title_justify   => 'center',
        legend_location => 'none'
      );
    }
  }
  foreach my $bin (@clusterBins) {
    $clusters_graphics->hit_quality_graph (
      bins            => [$bin], 
      metagenomes     => ['total'],
      sizes           => ['total'],
      extracted       => ['total'],
      layers          => ['total'],
      max_evalue      => '1e-10',
      min_length      => '100',
      categories      => \@categories,
      colors          => \@colors,
      low             => 50,
      high            => 100,
      file_name       => $output_directory . '/clusters/hit_quality/' . $bin . '.gif',
      title           => $cyano_data->long_description(bin => $bin),
      title_justify   => 'center',
      legend_location => 'none'
    );
  }

}
###################################################################################################


###################################################################################################
## Produces all of the Genome Mapped Graphics
###################################################################################################
sub produce_genome_graphs {
  my @paired = (
    'paired_normal_short',
    'paired_normal_long',
    'paired_normal_good',
    'paired_antinormal_short',
    'paired_antinormal_long',
    'paired_antinormal_good',
    'paired_outie_short',
    'paired_outie_long',
    'paired_outie_good',
    'paired_good_short',
    'paired_good_long',
    'paired_good_good'
  );
  my @categories = ('paired_nonsyntenous', 'paired_syntenous');
  my @colors = ('blue', 'red');
  my @pixel_size = (2, 2);
  my @connected = (1, 1);
  foreach my $metagenome (@metagenomes) {
    foreach my $bin (@bac_bins) {
      $bac_graphics->genome_graph (
        width            => 500,
        height           => 300,
        normal_font      => $normal_font,
        title_font       => $title_font,
        normal_font_size => 12,
        title_font_size  => 12,
        bins             => [$bin], 
        metagenomes      => [$metagenome],
        sizes            => ['total'],
        extracted        => ['total'],
        layers           => ['total'],
        max_evalue       => '1e-10',
        min_length       => '100',
        categories       => \@categories,
        colors           => \@colors,
        low              => 70,
        high             => 100,
        pixel_size       => \@pixel_size,
        connected        => \@connected,
        x_labels         => $tic_labels->{$bin},
        x_label_location => $tic_locations->{$bin},
        file_name        => $output_directory . '/bac/genome-mapped/' . $metagenome . '/' . $bin . '.gif',
#        titles           => [$bac_data->long_description(bin => $bin)],
#        title_justify    => 'center',
        legend_location  => 'bottom',
        legend_justify   => 'center'
      );
      foreach my $type (@paired) {
        $bac_graphics->genome_graph (
          width            => 500,
          height           => 300,
          normal_font      => $normal_font,
          title_font       => $title_font,
          normal_font_size => 12,
          title_font_size  => 12,
          bins             => [$bin], 
          metagenomes      => [$metagenome],
          sizes            => ['total'],
          extracted        => ['total'],
          layers           => ['total'],
          max_evalue       => '1e-10',
          min_length       => '100',
          categories       => [$type],
          colors           => ['blue'],
          low              => 70,
          high             => 100,
          pixel_size       => [2],
          connected        => [1],
          x_labels         => $tic_labels->{$bin},
          x_label_location => $tic_locations->{$bin},
          file_name        => $output_directory . '/bac/genome-mapped/' . $metagenome . '/' . $type . '/' . $bin . '.gif',
#          titles           => [$bac_data->long_description(bin => $bin)],
#          title_justify    => 'center',
          legend_location  => 'none'
        );
      }
    }
    foreach my $bin (@cyano_bins) {
      $cyano_graphics->genome_graph (
        width            => 500,
        height           => 300,
        normal_font      => $normal_font,
        title_font       => $title_font,
        normal_font_size => 12,
        title_font_size  => 12,
        bins             => [$bin], 
        metagenomes      => [$metagenome],
        sizes            => ['total'],
        extracted        => ['total'],
        layers           => ['total'],
        max_evalue       => '1e-10',
        min_length       => '100',
        categories       => \@categories,
        colors           => \@colors,
        low              => 70,
        high             => 100,
        pixel_size       => \@pixel_size,
        connected        => \@connected,
        x_labels         => $tic_labels->{$bin},
        x_label_location => $tic_locations->{$bin},
        file_name        => $output_directory . '/cyano/genome-mapped/' . $metagenome . '/' . $bin . '.gif',
#        titles           => [$cyano_data->long_description(bin => $bin)],
#        title_justify    => 'center',
        legend_location  => 'none'
      );
      foreach my $type (@paired) {
        $cyano_graphics->genome_graph (
          width            => 500,
          height           => 300,
          normal_font      => $normal_font,
          title_font       => $title_font,
          normal_font_size => 12,
          title_font_size  => 12,
          bins             => [$bin], 
          metagenomes      => [$metagenome],
          sizes            => ['total'],
          extracted        => ['total'],
          layers           => ['total'],
          max_evalue       => '1e-10',
          min_length       => '100',
          categories       => [$type],
          colors           => ['blue'],
          low              => 70,
          high             => 100,
          pixel_size       => [2],
          connected        => [1],
          x_labels         => $tic_labels->{$bin},
          x_label_location => $tic_locations->{$bin},
          file_name        => $output_directory . '/cyano/genome-mapped/' . $metagenome . '/' . $type . '/' . $bin . '.gif',
#          titles           => [$bac_data->long_description(bin => $bin)],
#          title_justify    => 'center',
          legend_location  => 'none',
          low              => 70,
          high             => 100
        );
      }
    }
  }
}
###################################################################################################

###################################################################################################
## Produces all of the Tiled Genome Graphics
###################################################################################################
sub produce_tiled_genome_graphs {
  my @categories = ('paired_nonsyntenous', 'paired_syntenous');
  my @colors = ('blue', 'red');
  my @pixel_size = (2, 2);
  my @connected = (0, 1);
  foreach my $metagenome (@metagenomes) {
    foreach my $bin (@bac_bins) {
      $bac_graphics->tiled_genome_graph (
        width            => 500,
        height           => 300,
        normal_font      => $normal_font,
        title_font       => $title_font,
        normal_font_size => 12,
        title_font_size  => 12,
        bins             => [$bin], 
        metagenomes      => [$metagenome],
        sizes            => ['total'],
        extracted        => ['total'],
        layers           => ['total'],
        max_evalue       => '1e-10',
        min_length       => '100',
        categories       => \@categories,
        colors           => \@colors,
        pixel_size       => \@pixel_size,
        connected        => \@connected,
        x_labels         => $tic_labels->{$bin},
        x_label_location => $tic_locations->{$bin},
        file_name        => $output_directory . '/bac/tiled-genome/' . $metagenome . '/' . $bin . '.gif',
#        titles           => [$bac_data->long_description(bin => $bin)],
#        title_justify    => 'center',
        legend_location  => 'none'
      );
    }
    foreach my $bin (@cyano_bins) {
      $cyano_graphics->tiled_genome_graph (
        width            => 500,
        height           => 300,
        normal_font      => $normal_font,
        title_font       => $title_font,
        normal_font_size => 12,
        title_font_size  => 12,
        bins             => [$bin], 
        metagenomes      => [$metagenome],
        sizes            => ['total'],
        extracted        => ['total'],
        layers           => ['total'],
        max_evalue       => '1e-10',
        min_length       => '100',
        categories       => \@categories,
        colors           => \@colors,
        pixel_size       => \@pixel_size,
        x_labels         => $tic_labels->{$bin},
        x_label_location => $tic_locations->{$bin},
        connected        => \@connected,
        file_name        => $output_directory . '/cyano/tiled-genome/' . $metagenome . '/' . $bin . '.gif',
#        titles           => [$cyano_data->long_description(bin => $bin)],
#        title_justify    => 'center',
        legend_location  => 'none'
      );
    }
  }
}
###################################################################################################

###################################################################################################
## Produces all of the Tiled Genome Data
###################################################################################################
sub produce_tiled_genome_data {
  foreach my $metagenome (@metagenomes) {
    foreach my $bin (@cyano_bins) {
      $cyano_text->tiled_genome_data (
        bins            => [$bin], 
        metagenomes     => [$metagenome],
        sizes           => ['total'],
        extracted       => ['total'],
        layers          => ['total'],
        max_evalue      => '1e-10',
        min_length      => '100',
        categories      => ['paired_syntenous'],
        rrna_16s        => $rrna_16s->{$bin},
        file_name       => $output_directory . '/cyano/tiled-genome-data/' . $metagenome . '/' . $bin . '-syntenous.txt',
        titles          => [$cyano_data->long_description(bin => $bin) . ' - Syntenous'],
      );
      $cyano_text->tiled_genome_data (
        bins            => [$bin], 
        metagenomes     => [$metagenome],
        sizes           => ['total'],
        extracted       => ['total'],
        layers          => ['total'],
        max_evalue      => '1e-10',
        min_length      => '100',
        categories      => ['paired_nonsyntenous'],
        rrna_16s        => $rrna_16s->{$bin},
        file_name       => $output_directory . '/cyano/tiled-genome-data/' . $metagenome . '/' . $bin . '-nonsyntenous.txt',
        titles          => [$cyano_data->long_description(bin => $bin) . ' - Non Syntenous'],
      );
      $cyano_text->synteny_binomial_test (
        alpha           => $alpha,
        bins            => [$bin], 
        metagenomes     => [$metagenome],
        sizes           => ['total'],
        extracted       => ['total'],
        layers          => ['total'],
        max_evalue      => '1e-10',
        min_length      => '100',
        categories      => ['total'],
        file_name       => $output_directory . '/cyano/synteny_binomial_test/' . $metagenome . '/' . $bin . '.txt',
        titles          => [$cyano_data->long_description(bin => $bin)],
      );
      $cyano_text->rrna_16s_binomial_test (
        alpha           => $alpha,
        bins            => [$bin], 
        metagenomes     => [$metagenome],
        sizes           => ['total'],
        extracted       => ['total'],
        layers          => ['total'],
        max_evalue      => '1e-10',
        min_length      => '100',
        categories      => ['total'],
        rrna_16s        => $rrna_16s->{$bin},
        file_name       => $output_directory . '/cyano/rrna_16s_binomial_test/' . $metagenome . '/' . $bin . '.txt',
        titles          => [$cyano_data->long_description(bin => $bin)],
      );
      $cyano_text->rrna_16s_range_test (
        alpha           => $alpha,
        bins            => [$bin], 
        metagenomes     => [$metagenome],
        sizes           => ['total'],
        extracted       => ['total'],
        layers          => ['total'],
        max_evalue      => '1e-10',
        min_length      => '100',
        categories      => ['total'],
        rrna_16s        => $rrna_16s->{$bin},
        file_name       => $output_directory . '/cyano/rrna_16s_range_test/' . $metagenome . '/' . $bin . '.txt',
        titles          => [$cyano_data->long_description(bin => $bin)],
      );
    }
  }
}
###################################################################################################

###################################################################################################
## Produces all of the Correspondence Tables.
###################################################################################################
sub produce_correspondence_tables {
  my $fasta = new Pigeon::Fasta (fileName => $cyano_metagenome_file);
  my %libraries;
  foreach my $seq ($fasta->getAll()) {
    push @{$libraries{$seq->{meta}{library_name}}}, $seq->{identifier};
  }
  # Create directory structure.
  createDirectory (directory => $output_directory . '/correspondence');
  foreach my $library (keys %libraries) {
    open FILE, '>' . $output_directory . '/correspondence/' . $library . '.txt' or die "Can't write to file: $!\n";
    print FILE "ID\tBarcode\tRunID\tWellCoordinates\t96WellQuadrant\t96WellCoordinates\n";
    foreach my $id (@{$libraries{$library}}) {
      my $seq = $fasta->get (identifier => $id);
      print FILE $id . "\t";
      print FILE $seq->{meta}{sequencer_plate_barcode} . "\t";
      print FILE $seq->{meta}{sequencer_run_id} . "\t";
      print FILE $seq->{meta}{sequencer_plate_well_coordinates} . "\t";
      print FILE $seq->{meta}{sequencer_plate_96well_quadrant} . "\t";
      print FILE $seq->{meta}{sequencer_plate_96well_coordinates} . "\n";
    }
    close FILE;
  }
}
###################################################################################################

###################################################################################################
## Produces all of the Mate Type Tables.
###################################################################################################
sub produce_mate_type_tables {
  # Cyano BACs
  my %cyanoLibraries;
  my %cyanoReads = $cyano_data->reads();
  foreach my $id (keys %cyanoReads) {
    push @{$cyanoLibraries{$cyanoReads{$id}{source}}}, $id;
  }
  # Create directory structure.
  createDirectory (directory => $output_directory . '/mate_type/cyano/');
  foreach my $library (keys %cyanoLibraries) {
    open FILE, '>' . $output_directory . '/mate_type/cyano/' . $library . '.txt' or die "Can't write to file: $!\n";
    print FILE "ID\tMate\tType\tBin\tMateBin\n";
    foreach my $id (@{$cyanoLibraries{$library}}) {
      print FILE $id . "\t";
      print FILE $cyanoReads{$id}{clone_pair} . "\t";
      print FILE $cyanoReads{$id}{type} . "\t"; 
      print FILE $cyanoReads{$id}{bin} . "\t";
      print FILE $cyanoReads{$cyanoReads{$id}{clone_pair}}{bin} . "\t" if ($cyanoReads{$id}{clone_pair} ne 'null');
      print FILE $cyanoReads{$id}{percent_identity} . "\t";
      print FILE $cyanoReads{$cyanoReads{$id}{clone_pair}}{percent_identity} . "\t"  if ($cyanoReads{$id}{clone_pair} ne 'null');
      print FILE "\n";
    }
  }
  # Random BACs
  my %bacLibraries;
  my %bacReads = $bac_data->reads();
  foreach my $id (keys %bacReads) {
    push @{$bacLibraries{$bacReads{$id}{source}}}, $id;
  }
  # Create directory structure.
  createDirectory (directory => $output_directory . '/mate_type/bac');
  foreach my $library (keys %bacLibraries) {
    open FILE, '>' . $output_directory . '/mate_type/bac/' . $library . '.txt' or die "Can't write to file: $!\n";
    print FILE "ID\tMate\tType\tBin\tMateBin\tIdentity\tMateIdentity\n";
    foreach my $id (@{$bacLibraries{$library}}) {
      print FILE $id . "\t";
      print FILE $bacReads{$id}{clone_pair} . "\t";
      print FILE $bacReads{$id}{type} . "\t"; 
      print FILE $bacReads{$id}{bin} . "\t";
      print FILE $bacReads{$bacReads{$id}{clone_pair}}{bin} . "\t"  if ($bacReads{$id}{clone_pair} ne 'null');
      print FILE $bacReads{$id}{percent_identity} . "\t";
      print FILE $bacReads{$bacReads{$id}{clone_pair}}{percent_identity} . "\t"  if ($bacReads{$id}{clone_pair} ne 'null');
      print FILE "\n";
    }
  }
  close FILE;
}

###################################################################################################
## Run various subroutines to create the graphics
###################################################################################################

print "Producing Rank Abundance Graphics...\n";
produce_rank_abundance_graphs();

print "Producing Hit Quality Graphics...\n";
produce_hit_quality_graphs();

print "Producing Genome Mapped Graphics...\n";
produce_genome_graphs();

print "Producing Tiled Genome Graphics...\n";
produce_tiled_genome_graphs();

print "Producing Tiled Genome Data...\n";
produce_tiled_genome_data();

print "Producing Correspondece Tables...\n";
produce_correspondence_tables();

print "Producing Mate Type Tables...\n";
produce_mate_type_tables();

###################################################################################################


=head1 NAME

  Pigeon::Data - Creates a Data object from a tab delimited file.

=head1 SYNOPSIS

  Private usage by Pigeon.

=head1 DESCRIPTION

  This package creates a Pigeon::Data object from a tab delimited file.

=head1 DEPENDENCIES

  This package depends on various packages in the Pigeon hierarchy.

=head1 FEEDBACK

=head2 Mailing Lists

  No mailing list currently exists.

=head2 Reporting Bugs

  Report bugs to the author directly.

=head1 AUTHOR - Jason Wood

  Email sandain-at-hotmail.com

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2009  Jason Wood, Montana State University

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.

=head1 APPENDIX

  The rest of the documentation details each of the object methods.
  Internal methods are usually preceded with a _

=cut

package Pigeon::Data;

use strict;
use warnings;

use Pigeon::Data::Assembly;
use Pigeon::Data::PCA;
use Pigeon::Data::Ocount;
use Pigeon::Cluster;
use Pigeon::Tools qw(:all);
use Pigeon::Statistics;

## Global Variables
my $int_max = 100000;
my $int_min = -100000;

my $default_synteny_error = 0.3;        # Default error used in Synteny calculation

my @categories = (
  "nopair",  "unpaired", "paired_na",
  "paired_normal_short", "paired_normal_long", "paired_normal_good",
  "paired_antinormal_short", "paired_antinormal_long", "paired_antinormal_good", "paired_outie_short",
  "paired_outie_long",  "paired_outie_good", "paired_good_short",
  "paired_good_long", "paired_good_good", "paired_syntenous"
);

my %short_description = (
  "null"                                                => "null",
  "acidobacteria_bacterium_ellin345"                    => "Acid",
  "anabaena"                                            => "Anab",
  "aquifex_aeolicus_vf5"                                => "Aaeo",
  "bacteroides_vulgatus_atcc_8482"                      => "Bvul",
  "caldicellulosiruptor_saccharolyticus"                => "Cac",
  "carboxydothermus_hydrogenoformans_z-2901"            => "Chyd",
  "chloracidobacterium_thermophilum"                    => "Cthe",
  "chlorobium_tepidum"                                  => "Ctep",
  "chloroflexus_aggregans"                              => "Cagg",
  "chloroflexus_aurantiacus"                            => "Caur",
  "chloroflexus_sp._y-400-fl"                           => "CY400",
  "chloroflexus_sp._396-1"                              => "C396",
  "chloroflexus_sp._j-10-fl"                            => "CJ10",
  "chloroherpeton_thalassium"                           => "Ctha",
  "cyanobacterium_sp._jsc-1"				=> "JSC-1",
  "desulfovibrio_desulfuricans"                         => "Ddes",
  "gemmata_obscuriglobus"                               => "Gobs",
  "gfp"                                                 => "GFP",
  "gloeobacter"                                         => "Gloe",
  "haloferax_volcanii"                                  => "Hvol",
  "herpetosiphon_aurantiacus_atcc_23779"                => "Haur",
  "microcoleus_chthonoplastes_pcc_7420"                 => "Mcht",
  "methanothermobacter_thermautotrophicus_str._delta_h" => "Mthe",
  "nostoc_sp._pcc_7120"                                 => "Nost",
  "rhodoferax_ferrireducens_t118"                       => "Rfer",
  "rhodopseudomonas_palustris_tie-1"                    => "Rpal",
  "roseiflexus_castenholzii_hlo8"                       => "Rcas",
  "roseiflexus_sp._rs1"                                 => "Ros",
  "synechococcus_sp._os-type_a_strain"                  => "SA",
  "synechococcus_sp._os-type_a2_strain"                 => "SA2",
  "synechococcus_sp._os-type_a'_strain"                 => "SA'",
  "synechococcus_sp._os-type_b_strain"                  => "SB",
  "synechococcus_sp._os-type_b'_strain"                 => "SB'",
  "symbiobacterium_thermophilum"                        => "Sthe",
  "thermoanaerobacter_ethanolicus_atcc_33223"           => "Tpse",
  "thermoanaerobacter_tengcongensis"                    => "Tten",
  "thermodesulfobacterium_commune_dsm_2178"             => "Tcom",
  "thermodesulfovibrio_yellowstonii"                    => "Tyel",
  "thermomicrobium_roseum"                              => "Tros",
  "thermoproteus_neutrophilus_v24sta"                   => "Tneu",
  "thermosynechococcus_elongatus_bp-1"                  => "Telo",
  "thermotoga_maritima"                                 => "Tmar",
  "thermus_thermophilus_hb8"                            => "Tthe",
  "thermus_thermophilus_hb27"                           => "Tthe27",
  "ms"                                                  => 'MS',
  "os"                                                  => 'OS',
  "high"                                                => 'High',
  "low"                                                 => 'Low',
  "mshigh"                                              => 'MS High',
  "oshigh"                                              => 'OS High',
  "mslow"                                               => 'MS Low',
  "oslow"                                               => 'OS Low',
  "total"                                               => 'Total',
  "nopair"                                              => 'NoPair',
  "unpaired"                                            => 'Unpaired',
  "paired_na"                                           => 'P-N/A',
  "paired_overlap"                                      => 'P-O',
  "paired_normal_short"                                 => 'P-N-S',
  "paired_normal_long"                                  => 'P-N-L',
  "paired_normal_good"                                  => 'P-N-G',
  "paired_antinormal_short"                             => 'P-A-S',
  "paired_antinormal_long"                              => 'P-A-L',
  "paired_antinormal_good"                              => 'P-A-G',
  "paired_outie_short"                                  => 'P-O-S',
  "paired_outie_long"                                   => 'P-O-L',
  "paired_outie_good"                                   => 'P-O-G',
  "paired_good_short"                                   => 'P-G-S',
  "paired_good_long"                                    => 'P-G-L',
  "paired_good_good"                                    => 'Synt',
  "paired_syntenous"                                    => 'Synt',
  "paired_nonsyntenous"                                 => 'Nonsynt',
  "paired"                                              => 'Paired',
  "cluster1"						=> '1',
  "cluster2"						=> '2',
  "cluster3"						=> '3',
  "cluster4"						=> '4',
  "cluster5"						=> '5',
  "cluster6"						=> '6',
  "cluster7"						=> '7',
  "cluster8"						=> '8',
  "cluster9"						=> '9',
  "cluster10"						=> '10',
  "cluster11"						=> '11',
  "cluster12"						=> '12',
  "cluster13"						=> '13',
  "cluster14"						=> '14',
  "cluster15"						=> '15',

);

my %long_description = (
  "null"                                                => "null",
  "acidobacteria_bacterium_ellin345"                    => "Acidobacterium sp. Ellin345",
  "anabaena"                                            => "Anabaena sp. strain PCC 7120",
  "aquifex_aeolicus_vf5"                                => "Aquifex aeolicus VF5",
  "bacteroides_vulgatus_atcc_8482"                      => "Bacteroides vulgatus ATCC 8482",
  "caldicellulosiruptor_saccharolyticus"                => "Caldicellulosiruptor saccharolyticus",
  "carboxydothermus_hydrogenoformans_z-2901"            => "Carboxydothermus hydrogenoformans Z-2901",
  "chloracidobacterium_thermophilum"                    => "Candidatus Chloracidobacterium thermophilum",
  "chlorobium_tepidum"                                  => "Chlorobium tepidum",
  "chloroflexus_aggregans"                              => "Chloroflexus aggregans",
  "chloroflexus_aurantiacus"                            => "Chloroflexus aurantiacus",
  "chloroflexus_sp._y-400-fl"                           => "Chloroflexus sp. Y-400-fl",
  "chloroflexus_sp._396-1"                              => "Chloroflexus sp. 396-1",
  "chloroflexus_sp._j-10-fl"                            => "Chloroflexus sp. J-10-fl",
  "chloroherpeton_thalassium"                           => "Chloroherpeton thalassium ATCC 35110",
  "cyanobacterium_sp._jsc-1"				=> "Cyanobacterium sp. strain JSC-1",
  "desulfovibrio_desulfuricans"                         => "Desulfovibrio desulfuricans",
  "gemmata_obscuriglobus"                               => "Gemmata obscuriglobus",
  "gfp"                                                 => "GFP Assembly",
  "gloeobacter"                                         => "Gloebacter violaceus PCC 7421",
  "haloferax_volcanii"                                  => "Haloferax volcanii",
  "herpetosiphon_aurantiacus_atcc_23779"                => "Herpetosiphon aurantiacus ATCC 23779",
  "methanothermobacter_thermautotrophicus_str._delta_h" => "Methanothermobacterium thermautotrophicum str. Delta H",
  "microcoleus_chthonoplastes_pcc_7420"                 => "Microcoleus chthonoplastes PCC 7420",
  "mystery_points"                                      => "Mystery Points",
  "nostoc_sp._pcc_7120"                                 => "Nostoc sp. strain PCC 7120",
  "rhodoferax_ferrireducens_t118"                       => "Rhodoferax ferrireducens T118",
  "rhodopseudomonas_palustris_tie-1"                    => "Rhodopseudomonas palustris TIE-1",
  "roseiflexus_castenholzii_hlo8"                       => "Roseiflexus castenholzii HLO8",
  "roseiflexus_sp._rs1"                                 => "Roseiflexus sp. strain RS1",
  "synechococcus_sp._os-type_a_strain"                  => "Synechococcus sp. strain A",
  "synechococcus_sp._os-type_a2_strain"                 => "Synechococcus sp. strain A2",
  "synechococcus_sp._os-type_a'_strain"                 => "Putative Synechococcus sp. strain A'",
  "synechococcus_sp._os-type_b_strain"                  => "Synechococcus sp. strain B",
  "synechococcus_sp._os-type_b'_strain"                 => "Synechococcus sp. strain B'",
  "symbiobacterium_thermophilum"                        => "Symbiobacterium thermophilum",
  "thermoanaerobacter_ethanolicus_atcc_33223"           => "Thermoanaerobacter pseudoethanolicus ATCC 33223",
  "thermoanaerobacter_tengcongensis"                    => "Thermoanaerobacter tengcongensis",
  "thermodesulfobacterium_commune_dsm_2178"             => "Thermodesulfobacterium commune DSM 2178",
  "thermodesulfovibrio_yellowstonii"                    => "Thermodesulfovibrio yellowstonii YP87",
  "thermomicrobium_roseum"                              => "Thermomicrobium roseum ATCC 27502",
  "thermoproteus_neutrophilus_v24sta"                   => "Thermoproteus neutrophilus V24Sta",
  "thermosynechococcus_elongatus_bp-1"                  => "Thermosynechococcus elongatus BP-1",
  "thermotoga_maritima"                                 => "Thermotoga maritima",
  "thermus_thermophilus_hb8"                            => "Thermus thermophilus HB8",
  "thermus_thermophilus_hb27"                           => "Thermus thermophilus HB27",
  "ms"                                                  => "Mushroom Spring, combined temperatures",
  "os"                                                  => "Octopus Spring, combined temperatures",
  "high"                                                => "High temperature, combined springs",
  "low"                                                 => "Low temperature, combined springs",
  "mshigh"                                              => "Mushroom Spring ~65˚C",
  "oshigh"                                              => "Octopus Spring 58-67˚C",
  "mslow"                                               => "Mushroom Spring ~60˚C",
  "oslow"                                               => "Octopus Spring 53-63˚C",
  "total"                                               => "Combined springs and temperatures",
  "nopair"                                              => 'No Pair',
  "unpaired"                                            => 'Disjointly Recruited',
  "paired_na"                                           => 'Paired-N/A',
  "paired_overlap"                                      => 'Paired-Overlap',
  "paired_normal_short"                                 => 'Paired-Normal-Short',
  "paired_normal_long"                                  => 'Paired-Normal-Long',
  "paired_normal_good"                                  => 'Paired-Normal-Good',
  "paired_antinormal_short"                             => 'Paired-Antinormal-Short',
  "paired_antinormal_long"                              => 'Paired-Antinormal-Long',
  "paired_antinormal_good"                              => 'Paired-Antinormal-Good',
  "paired_outie_short"                                  => 'Paired-Outie-Short',
  "paired_outie_long"                                   => 'Paired-Outie-Long',
  "paired_outie_good"                                   => 'Paired-Outie-Good',
  "paired_good_short"                                   => 'Paired-Good-Short',
  "paired_good_long"                                    => 'Paired-Good-Long',
  "paired_good_good"                                    => 'Paired-Syntenous',
  "paired_syntenous"                                    => 'Jointly Recruited Syntenous',
  "paired_nonsyntenous"                                 => 'Jointly Recruited Nonsyntenous',
  "paired"                                              => 'Paired',
  # Mel's gene bins
  "apcab_syna"                                          => 'Syn A',
  "apcab_synbpr"                                        => "Syn B'",
  "apcab_m60c"                                          => 'm60c',
  "apcab_m65c"                                          => 'm65c',
  "aroa_syna"                                           => 'Syn A',
  "aroa_synbpr"                                         => "Syn B'",
  "aroa_m60c"                                           => 'm60c',
  "aroa_m65c"                                           => 'm65c',
  "rbsk_syna"                                           => 'Syn A',
  "rbsk_synbpr"                                         => "Syn B'",
  "rbsk_m60c"                                           => 'm60c',
  "rbsk_m65c"                                           => 'm65c',
  "cluster1"						=> 'Cluster 1',
  "cluster2"						=> 'Cluster 2',
  "cluster3"						=> 'Cluster 3',
  "cluster4"						=> 'Cluster 4',
  "cluster5"						=> 'Cluster 5',
  "cluster6"						=> 'Cluster 6',
  "cluster7"						=> 'Cluster 7',
  "cluster8"						=> 'Cluster 8',
  "cluster9"						=> 'Cluster 9',

);

my %genome_size = (
  "acidobacteria_bacterium_ellin345"                    => 5649312,
  "aquifex_aeolicus_vf5"                                => 1549995,
  "bacteroides_vulgatus_atcc_8482"                      => 5161500,
  "carboxydothermus_hydrogenoformans_z-2901"            => 2397998,
  "chloracidobacterium_thermophilum"                    => 2683362,
  "chloroflexus_aggregans"                              => 4684933,
  "chloroflexus_sp._396-1"                              => 264402,
  "chloroflexus_sp._j-10-fl"                            => 5258543,
  "chloroflexus_sp._y-400-fl"                           => 5268952,
  "chloroherpeton_thalassium"                           => 1881424,
  "cyanobacterium_sp._jsc-1"				=> 9467215,
  "herpetosiphon_aurantiacus_atcc_23779"                => 284345,
  "methanothermobacter_thermautotrophicus_str._delta_h" => 1741839,
  "microcoleus_chthonoplastes_pcc_7420"                 => 8651623,
  "nostoc_sp._pcc_7120"                                 => 7211789,
  "rhodoferax_ferrireducens_t118"                       => 4710094,
  "rhodopseudomonas_palustris_tie-1"                    => 5744041,
  "roseiflexus_castenholzii_hlo8"                       => 5723300,
  "roseiflexus_sp._rs1"                                 => 5801599,
  "synechococcus_sp._os-type_a_strain"                  => 2932766,
  "synechococcus_sp._os-type_a'_strain"                 => 2932766,  # Use Syn A as a guestimate...
  "synechococcus_sp._os-type_b'_strain"                 => 3046682,
  "thermoanaerobacter_ethanolicus_atcc_33223"           => 307954,
  "thermodesulfobacterium_commune_dsm_2178"             => 1785651,
  "thermodesulfovibrio_yellowstonii"                    => 2003217,
  "thermomicrobium_roseum"                              => 2002246,
  "thermoproteus_neutrophilus_v24sta"                   => 612693,
  "thermosynechococcus_elongatus_bp-1"                  => 2588177,
  "thermus_thermophilus_hb8"                            => 1849565,
);

=head2 new

  Title   : new
  Usage   : my $data = new Pigeon::Data(
              metablast_file => 'metablast.txt',
              metagenome_file => 'metagenome.fasta',
              synteny_error => 0.3
            );
  Function: Creates a new Pigeon::Data object for use in the Pigeon package.
  Returns : Pigeon::Data::Text object
  Args    : metablast_file: Location of metablast file
            metagenome_file: Location of metagenome file, optional
            synteny_error: Error level for Synteny calculations, optional

=cut

sub new {
  my $invocant = shift;
  my $class = ref($invocant) || $invocant;
  my %params = @_;
  my $self = {
    reads         => undef,
    forced        => undef,
    assembly      => undef,
    pca           => undef,
    cluster       => undef,
    synteny_error => undef
  };
  bless $self => $class;
  # Seed the randomizer with the current time
  srand (time() ^($$ + ($$ << 15)));

  if (defined $params{synteny_error}) {
    $self->{synteny_error} = $params{synteny_error};
  }
  else {
    $self->{synteny_error} = $default_synteny_error;
  }
  if (defined $params{metablast_file}) {
    $self->{reads} = $self->_parse_metablast (file_name => $params{metablast_file});
  }
  if (defined $params{metagenome_file}) {
    $self->_parse_metagenome (file_name => $params{metagenome_file});
    $self->_add_metagenome_info();
  }
  return $self;
}

=head2 long_description

  Title   : long_description
  Usage   : $data->long_description('syna');
  Function: Returns a long description of the given bin.
  Returns : String containing the description
  Args    : bin: Any of the valid bins

=cut

sub long_description {
  my $self = shift;
  my %params = @_;
  if (defined $params{bin} && defined $long_description{$params{bin}}) {
    return $long_description{$params{bin}};
  }
  elsif (defined $params{bin}) {
    return $params{bin};
  }
  else {
    return '';
  }
}

=head2 short_description

  Title   : short_description
  Usage   : $data->short_description('syna');
  Function: Returns a short description of the given bin.
  Returns : String containing the description
  Args    : bin: Any of the valid bins

=cut

sub short_description {
  my $self = shift;
  my %params = @_;
  if (defined $params{bin} && defined $short_description{$params{bin}}) {
    return $short_description{$params{bin}};
  }
  else {
    return '';
  }
}

=head2 categories

  Title   : categories
  Usage   : my @categories = $data->categories;
  Function: Returns an array containing the various categories.
  Returns : Array containing the various categories

=cut

sub categories {
  my $self = shift;
  return @categories;
}

=head2 genome_size

  Title   : genome_size
  Usage   : $data->genome_size('syna');
  Function: Returns the approximate genome size of the provided bin
  Returns : Integer containing the approximate genome size
  Args    : bin: Any of the valid bins

=cut

sub genome_size {
  my $self = shift;
  my %params = @_;
  if (defined $params{bin} && defined $genome_size{$params{bin}}) {
    return $genome_size{$params{bin}};
  }
  else {
    return 0;
  }
}

=head2 reads

  Title    : reads
  Usage    : my %reads = $data->reads();
  Function : Returns a hash of reads that meet the given options.
  Returns  : Hash of reads
  Args     : ids: Array reference of valid ids to return, optional
             bins: Array reference of valid bins to include, defaults to total
             low: Low percent_id value to return, defaults to 0
             high: High percent_id value to return, defaults to 100
             min_evalue: Minimum e value, default 0
             max_evalue: Maximum e value, default 1e-10
             min_length: Minimum alignment length, default 0
             max_length: Maximum alignment length, default int_max
             metagenomes: Array reference of valid metagenomes to include, defaults to total
               Currently available:
                 mslow:   Mushroom Spring, low temperature
                 mshigh:  Mushroom Spring, high temperature
                 oslow:   Octopus Spring, low temperature, 60*C
                 oshigh:  Octopus Spring, high temperature, 65*C
                 ms:      Mushroom Spring, combined sample from both temperatures
                 os:      Octopus Spring, combined sample from both temperatures
                 low:     Low temperature, combined sample from both springs
                 high:    High temperature, combined sample from both springs
                 total:   Combined sample from both springs and both temperatures
             sizes: Array reference containing valid sizes, defaults to total
               Currently available: 2-3 kb, 3-4 kb, 4-5 kb, 5-6 kb, 8-9 kb, 10-12 kb, total
             extracted: Array reference of valid extracted to include, defaults to total
               Currently available: TIGR, MSU, total
             layers: Array reference of valid layers to include, defaults to total
               Currently available: top 1mm, 1mm below top, bottom 1mm, total
             categories: Array reference of categories to include, defaults to total
               Currently available:
                 nopair:                   Include reads with no pair.
                 unpaired:                 Include Unpaired reads.
                 paired_na:                Include Paired clone pairs on different contigs.
                 paired_overlap:           Include Paired-Overlap type clone pairs.
                 paired_normal_short:      Include Paired-Normal-Short type clone pairs.
                 paired_normal_long:       Include Paired-Normal-Long type clone pairs.
                 paired_normal_good:       Include Paired-Normal type clone pairs.
                 paired_antinormal_short:  Include Paired-AntiNormal-Short type clone pairs.
                 paired_antinormal_long:   Include Paired-AntiNormal-Long type clone pairs.
                 paired_antinormal_good:   Include Paired-AntiNormal type clone pairs.
                 paired_outie_short:       Include Paired-Outie-Short type clone pairs.
                 paired_outie_long:        Include Paired-Outie-Long type clone pairs.
                 paired_outie_good:        Include Paired-Outie type clone pairs.
                 paired_good_short:        Include Paired-Short type clone pairs.
                 paired_good_long:         Include Paired-Long type clone pairs.
                 paired_good_good:         Include Paired-Good type clone pairs.
                 paired_syntenous:         Include Paired-Syntenous type clone pairs.
                 paired_nonsyntenous:      Include Paired-Normal, Paired-AntiNormal, Paired-Outie, Paired-Short, Paired-Long type clone pairs.
                 paired:                   Include Paired-Syntenous and Paired-NonSyntenous type clone pairs.
                 total:                    Include all reads.

=cut

sub reads {
  my $self = shift;
  my %params = @_;
  my (%reads, %return);
  # Set defaults parameters.
  if (not defined $params{bins}) {
    $params{bins} = ['total'];
  }
  if (not defined $params{metagenomes}) {
    $params{metagenomes} = ['total'];
  }
  if (not defined $params{sizes}) {
    $params{sizes} = ['total'];
  }
  if (not defined $params{extracted}) {
    $params{extracted} = ['total'];
  }
  if (not defined $params{layers}) {
    $params{layers} = ['total'];
  }
  if (not defined $params{categories}) {
    $params{categories} = ['total'];
  }
  if (not defined $params{low}) {
    $params{low} = 0;
  }
  if (not defined $params{high}) {
    $params{high} = 100;
  }
  if (not defined $params{min_evalue}) {
    $params{min_evalue} = 0;
  }
  if (not defined $params{max_evalue}) {
    $params{max_evalue} = '1e-10';
  }
  if (not defined $params{min_length}) {
    $params{min_length} = 0;
  }
  if (not defined $params{max_length}) {
    $params{max_length} = $int_max;
  }
  if (not defined $params{ids}) {
    my @ids = keys %{$self->{reads}};
    $params{ids} = \@ids;
  }
  # Check each read to make sure its values are within the correct range, otherwise assign the read to the null bin.
  foreach my $id (@{$params{ids}}) {
    if ( defined $self->{reads}{$id} &&
         (defined $self->{reads}{$id}{percent_identity} && defined $self->{reads}{$id}{e_value}) &&
         (defined $self->{reads}{$id}{query_start} && defined $self->{reads}{$id}{query_end}) && 
         ($self->{reads}{$id}{percent_identity} >= $params{low} && $self->{reads}{$id}{percent_identity} <= $params{high}) &&
         ($self->{reads}{$id}{e_value} >= $params{min_evalue} && $self->{reads}{$id}{e_value} <= $params{max_evalue}) &&
         (abs ($self->{reads}{$id}{query_end} - $self->{reads}{$id}{query_start}) >= $params{min_length}) &&
         (abs ($self->{reads}{$id}{query_end} - $self->{reads}{$id}{query_start}) <= $params{max_length})
       ) {
      foreach my $key (keys %{$self->{reads}{$id}}) {
        $reads{$id}{$key} = $self->{reads}{$id}{$key};
      }
    }
    elsif (defined $self->{reads}{$id}) {
      foreach my $key (keys %{$self->{reads}{$id}}) {
        $reads{$id}{$key} = $self->{reads}{$id}{$key};
      }
      $reads{$id}{bin}                = 'null';
      $reads{$id}{contig}             = 'null';
      $reads{$id}{query_start}        = 0;
      $reads{$id}{query_end}          = 0;
      $reads{$id}{subject_start}      = 0;
      $reads{$id}{subject_end}        = 0;
      $reads{$id}{percent_identity}   = 0;
      $reads{$id}{percent_similarity} = 0;
      $reads{$id}{score}              = 0;
      $reads{$id}{query_strand}       = 0;
      $reads{$id}{subject_strand}     = 0;
      $reads{$id}{e_value}            = $int_max;
    }
  }
  # Determine type for each read
  foreach my $id (keys %reads) {
    my ($binb, $contigb);
    # Get clone pair's bin and contig.
    if (defined $reads{$id}{clone_pair} && $reads{$id}{clone_pair} ne 'null' && defined $reads{$reads{$id}{clone_pair}}) {
      $binb = $reads{$reads{$id}{clone_pair}}{bin};
      $contigb = $reads{$reads{$id}{clone_pair}}{contig};
    }
    # Check for clone mates that didn't meet the above criteria.
    elsif (defined $reads{$id}{clone_pair} && $reads{$id}{clone_pair} ne 'null') {
      $reads{$id}{clone_pair} = 'null';
      $binb = 'null';
      $contigb = 'null';
    }
    my $type = $self->_check_bins (
      bina    => $reads{$id}{bin},
      contiga => $reads{$id}{contig},
      binb    => $binb,
      contigb => $contigb
    );
    # Check for 'paired' reads are on the same contig, add direction and length.
    if ($type eq 'paired' and defined $genome_size{$reads{$id}{bin}}) {
      $type .= $self->_check_paired_type (
        forward_start   => $reads{$id}{subject_start},
        forward_end     => $reads{$id}{subject_end},
        forward_query   => $reads{$id}{query_strand},
        forward_subject => $reads{$id}{subject_strand},
        reverse_start   => $reads{$reads{$id}{clone_pair}}{subject_start},
        reverse_end     => $reads{$reads{$id}{clone_pair}}{subject_end},
        reverse_query   => $reads{$reads{$id}{clone_pair}}{query_strand},
        reverse_subject => $reads{$reads{$id}{clone_pair}}{subject_strand},
        genome_size     => $genome_size{$reads{$id}{bin}},
        size_range      => $reads{$id}{size}
      );
    }
    $reads{$id}{type} = $type;
  }
  # Only return reads that meet the requirements.
  foreach my $id (keys %reads) {
    if ( test_categories(item => $reads{$id}{type},      list => $params{categories}) &&
         _test (item => $reads{$id}{bin},        list => $params{bins}) &&
         _test (item => $reads{$id}{metagenome}, list => $params{metagenomes}) &&
         _test (item => $reads{$id}{size},       list => $params{sizes}) &&
         _test (item => $reads{$id}{extracted},  list => $params{extracted}) &&
         _test (item => $reads{$id}{layer},      list => $params{layers})
       ) { 
      foreach my $key (keys %{$reads{$id}}) {
        $return{$id}{$key} = $reads{$id}{$key};
      }
    }
  }
  return %return;
}

=head2 forced

  Title    : forced
  Usage    : 
  Function : Returns a hash of reads that meet the given options.
  Returns  : Hash of reads
  Args     : forced_bins: Array reference of valid bins to include
             bins: Array reference of valid bins to include, defaults to ['total']
             low: Low percent_id value to return, defaults to 0
             high: High percent_id value to return, defaults to 100
             metagenomes: Array reference of valid metagenomes to include, defaults to ['total']
               Currently available:
                 mslow:   Mushroom Spring, low temperature
                 mshigh:  Mushroom Spring, high temperature
                 oslow:   Octopus Spring, low temperature, 60*C
                 oshigh:  Octopus Spring, high temperature, 65*C
                 ms:      Mushroom Spring, combined sample from both temperatures
                 os:      Octopus Spring, combined sample from both temperatures
                 low:     Low temperature, combined sample from both springs
                 high:    High temperature, combined sample from both springs
                 total:   Combined sample from both springs and both temperatures
             sizes: Array reference containing valid sizes, defaults to ['total']
               Currently available: 2-3 kb, 3-4 kb, 4-5 kb, 5-6 kb, 8-9 kb, 10-12 kb, total
             extracted: Array reference of valid extracted to include, defaults to ['total']
               Currently available: TIGR, MSU, total
             layers: Array reference of valid layers to include, defaults to ['total']
               Currently available: top 1mm, 1mm below top, bottom 1mm, total
             categories: Array reference of categories to include, defaults to ['total']
               Currently available:
                 nopair:                   Include reads with no pair.
                 unpaired:                 Include Unpaired reads.
                 paired_na:                Include Paired clone pairs on different contigs.
                 paired_normal_short:      Include Paired-Normal-Short type clone pairs.
                 paired_normal_long:       Include Paired-Normal-Long type clone pairs.
                 paired_normal_good:       Include Paired-Normal type clone pairs.
                 paired_antinormal_short:  Include Paired-AntiNormal-Short type clone pairs.
                 paired_antinormal_long:   Include Paired-AntiNormal-Long type clone pairs.
                 paired_antinormal_good:   Include Paired-AntiNormal type clone pairs.
                 paired_outie_short:       Include Paired-Outie-Short type clone pairs.
                 paired_outie_long:        Include Paired-Outie-Long type clone pairs.
                 paired_outie_good:        Include Paired-Outie type clone pairs.
                 paired_good_short:        Include Paired-Short type clone pairs.
                 paired_good_long:         Include Paired-Long type clone pairs.
                 paired_good_good:         Include Paired-Good type clone pairs.
                 paired_syntenous:         Include Paired-Syntenous type clone pairs.
                 paired_nonsyntenous:      Include Paired-Normal, Paired-AntiNormal, Paired-Outie, Paired-Short, Paired-Long type clone pairs.
                 paired:                   Include Paired-Syntenous and Paired-NonSyntenous type clone pairs.
                 total:                    Include all reads.
=cut

sub forced {
  my $self = shift;
  my %params = @_;
  my (%forced, %return);
  # If the param forced_bin is not provided there is nothing to do.
  if (not defined $params{forced_bins}) {
    return;
  }
  # Set default parameters.
  if (not defined $params{bins}) {
    $params{bins} = ['total'];
  }
  if (not defined $params{metagenomes}) {
    $params{metagenomes} = ['total'];
  }
  if (not defined $params{sizes}) {
    $params{sizes} = ['total'];
  }
  if (not defined $params{extracted}) {
    $params{extracted} = ['total'];
  }
  if (not defined $params{layers}) {
    $params{layers} = ['total'];
  }
  if (not defined $params{categories}) {
    $params{categories} = ['total'];
  }
  if (not defined $params{low}) {
    $params{low} = 0;
  }
  if (not defined $params{high}) {
    $params{high} = 100;
  }
  if (not defined $params{min_evalue}) {
    $params{min_evalue} = 0;
  }
  if (not defined $params{max_evalue}) {
    $params{max_evalue} = '1e-10';
  }
  if (not defined $params{min_length}) {
    $params{min_length} = 0;
  }
  if (not defined $params{max_length}) {
    $params{max_length} = $int_max;
  }
  foreach my $forced_bin (@{$params{forced_bins}}) {
    if (defined $self->{forced}{$forced_bin}) {
      # Check each read to make sure its values are within the correct range, othwise assign the read to the null bin.
      foreach my $id (keys %{$self->{forced}{$forced_bin}}) {
        if ( ($self->{forced}{$forced_bin}{$id}{percent_identity} >= $params{low} && $self->{forced}{$forced_bin}{$id}{percent_identity} <= $params{high}) &&
             ($self->{forced}{$forced_bin}{$id}{e_value} >= $params{min_evalue} && $self->{forced}{$forced_bin}{$id}{e_value} <= $params{max_evalue}) &&
             (abs ($self->{forced}{$forced_bin}{$id}{query_end} - $self->{forced}{$forced_bin}{$id}{query_start}) >= $params{min_length}) &&
             (abs ($self->{forced}{$forced_bin}{$id}{query_end} - $self->{forced}{$forced_bin}{$id}{query_start}) <= $params{max_length})
           ) {
          $forced{$forced_bin}{$id} = $self->{forced}{$forced_bin}{$id};
        }
#        elsif ((($self->{forced}{$forced_bin}{$id}{percent_identity} < $params{low} || $self->{forced}{$forced_bin}{$id}{percent_identity} > $params{high}) ||
#                ($self->{forced}{$forced_bin}{$id}{e_value} < $params{min_evalue} || $self->{forced}{$forced_bin}{$id}{e_value} > $params{max_evalue}) ||
#                (abs ($self->{forced}{$forced_bin}{$id}{query_end} - $self->{forced}{$forced_bin}{$id}{query_start}) < $params{min_length}) ||
#                (abs ($self->{forced}{$forced_bin}{$id}{query_end} - $self->{forced}{$forced_bin}{$id}{query_start}) > $params{max_length}))
#              ) {
#          $forced{$forced_bin}{$id} = $self->{forced}{$forced_bin}{$id};
#          $forced{$forced_bin}{$id}{bin}                = 'null';
#          $forced{$forced_bin}{$id}{contig}             = 'null';
#          $forced{$forced_bin}{$id}{query_start}        = 0;
#          $forced{$forced_bin}{$id}{query_end}          = 0;
#          $forced{$forced_bin}{$id}{subject_start}      = 0;
#          $forced{$forced_bin}{$id}{subject_end}        = 0;
#          $forced{$forced_bin}{$id}{percent_identity}   = 0;
#          $forced{$forced_bin}{$id}{percent_similarity} = 0;
#          $forced{$forced_bin}{$id}{score}              = 0;
#          $forced{$forced_bin}{$id}{query_strand}       = 0;
#          $forced{$forced_bin}{$id}{subject_strand}     = 0;
#          $forced{$forced_bin}{$id}{e_value}            = $int_max;
#        }
      }
      # Determine type for each read
      foreach my $id (keys %{$forced{$forced_bin}}) {
        my ($forced_type, $forced_binb, $forced_contigb);
        if ($self->{reads}{$id}{clone_pair} ne 'null' && defined $forced{$forced_bin}{$self->{reads}{$id}{clone_pair}}) {
          $forced_binb = $forced{$forced_bin}{$self->{reads}{$id}{clone_pair}}{bin};
          $forced_contigb = $forced{$forced_bin}{$self->{reads}{$id}{clone_pair}}{contig};
        }
        $forced_type = $self->_check_bins (
          bina    => $forced{$forced_bin}{$id}{bin},
          contiga => $forced{$forced_bin}{$id}{contig},
          binb    => $forced_binb,
          contigb => $forced_contigb
        );
        if ($forced_type eq 'paired') {
          $forced_type .= $self->_check_paired_type (
            forward_start   => $forced{$forced_bin}{$id}{subject_start},
            forward_end     => $forced{$forced_bin}{$id}{subject_end},
            forward_query   => $forced{$forced_bin}{$id}{query_strand},
            forward_subject => $forced{$forced_bin}{$id}{subject_strand},
            reverse_start   => $forced{$forced_bin}{$self->{reads}{$id}{clone_pair}}{subject_start},
            reverse_end     => $forced{$forced_bin}{$self->{reads}{$id}{clone_pair}}{subject_end},
            reverse_query   => $forced{$forced_bin}{$self->{reads}{$id}{clone_pair}}{query_strand},
            reverse_subject => $forced{$forced_bin}{$self->{reads}{$id}{clone_pair}}{subject_strand},
            genome_size     => $genome_size{$forced_bin},
            size_range      => $self->{reads}{$id}{size}
          );
        }
        $forced{$forced_bin}{$id}{type} = $forced_type;
      }
      # Only return reads that meet the requirements.
      foreach my $id (keys %{$forced{$forced_bin}}) {
        if ( test_categories(item => $forced{$forced_bin}{$id}{type}, list => $params{categories}) &&
             _test (item => $self->{reads}{$id}{bin},            list => $params{bins}) &&
             _test (item => $self->{reads}{$id}{metagenome},     list => $params{metagenomes}) &&
             _test (item => $self->{reads}{$id}{size},           list => $params{sizes}) &&
             _test (item => $self->{reads}{$id}{extracted},      list => $params{extracted}) &&
             _test (item => $self->{reads}{$id}{layer},          list => $params{layers})
            ) { 
          $return{$forced_bin}{$id} = $forced{$forced_bin}{$id};
        }
      }
    }
  }
  return %return;
}

=head2 assembly

  Title    : assembly
  Usage    : my $assembly = $data->assembly(assembly_name => 'name');
  Function : Returns the Assembly with the provided name
  Returns  : The Assembly with the provided name.
  Args     : assembly_name: 

=cut

sub assembly {
  my $self = shift;
  my %params = @_;
  if (defined $params{assembly_name}) {
    return $self->{assembly}{$params{assembly_name}};
  }
}

=head2 clusters

  Title    : clusters
  Usage    : my @clusters = $text->clusters(pca_name => 'pca name', k => 20); -OR-
             my @clusters = $text->clusters(oligo_name => 'oligo name', k => 20);
  Function : Returns an array containing Cluster objects for the given pca_name and k.
  Returns  : Array containing Cluster objects for the given pca_name and k.
  Args     : k: Value of k for returned Clusters
             pca_name: name of PCA data to return
             -OR-
             oligo_name: name of oligocount data to return
             -OR-
             threeD_name: name of 3D scatterplot data to return

=cut

sub clusters {
  my $self = shift;
  my %params = @_;
  if (defined $params{pca_name} && defined $params{k}) {
    return @{$self->{cluster}{$params{pca_name}}->[$params{k}]};
  }
  elsif (defined $params{oligo_name} && defined $params{k}) {
    return @{$self->{cluster}{$params{oligo_name}}->[$params{k}]};
  }
  elsif (defined $params{threeD_name} && defined $params{k}) {
    return @{$self->{cluster}{$params{threeD_name}}->[$params{k}]};
  }
}

=head2 synteny_error

  Title    : synteny_error
  Usage    : $data->synteny_error(0.3);
  Function : Changes the error level used for synteny calculation.
  Returns  : Current synteny error
  Args     : error: Synteny error level to use in calculations

=cut

sub synteny_error {
  my $self = shift;
  my %params = @_;
  if (defined $params{error}) {
    $self->{synteny_error} = $params{error};
  }
  return $self->{synteny_error};
}

=head2 forced_bins

  Title    : forced_bins
  Usage    : @bins = $data->forced_bins();
  Function : Returns an array of bins that have been forced using the method add_forced_bins()
  Returns  : Array of bins
  Args     : error: Synteny error level to use in calculations

=cut

sub forced_bins {
  my $self = shift;
  return keys %{$self->{forced}};
}

=head2 remove_conserved

  Title    : remove_conserved
  Usage    : $data->remove_conserved(
               low              => 50,
               high             => 50,
               homolog_filename => $homologfile,
               genone_vs_gentwo => $genone,
               gentwo_vs_genone => $gentwo,
               oldnew_link      => $oldnew
             );
  Function : Removes conserved reads above and below the supplied NA ID cutoffs
  Args     : low: Lower bound of %NA ID
             high: Upper bound of %NA ID
             homolog_filename: name of file that contains three tab delimited columns - 
                               name of gene in genome 1,
                               name of gene in genome 2,
                               and the % NT ID between orthologs.
             genone_vs_gentwo: parsed blast file of genome 1 queried vs. genome 2 database
             gentwo_vs_genone: parsed blast file of genome 2 queried vs. genome 1 database
             oldnew_link: file linking old metagenome names with new JCVI ones 

=cut

sub remove_conserved {
  my $self = shift;
  my %params = @_;
  my @ids;
  if (defined $params{low} && defined $params{high} && defined $params{oldnew_link}) {
    my %conserved = $self->_screen_conserved(%params);
    my %lookup = $self->_oldnew_readname($params{oldnew_link});
    foreach my $id (keys %{$self->{reads}}) {
      if (defined $lookup{$id} && ! defined $conserved{$lookup{$id}}) {
        push @ids, $id;
      }
    }
  }
  return @ids;
}

=head2 change_putative_apr_reads

  Title    : change_putative_apr_reads
  Usage    : $data->change_putative_apr_reads(
               low => 80,
               high => 90
             );
  Function : Changes the bin of any Synechococcus A reads that have a %NA ID that falls
             between the provided Upper and Lower bounds to Putative Synechococcus A'.
  Args     : low: Lower bound of %NA ID
             high: Upper bound of %NA ID

=cut

sub change_putative_apr_reads {
  my $self = shift;
  my %params = @_;
  if (defined $params{low} && defined $params{high}) {
    foreach my $id (keys %{$self->{reads}}) {
      if ($self->{reads}{$id}{bin} eq "synechococcus_sp._os-type_a_strain" && $self->{reads}{$id}{percent_identity} >= $params{low} && $self->{reads}{$id}{percent_identity} <= $params{high}) {
        $self->{reads}{$id}{bin} = "synechococcus_sp._os-type_a'_strain";
      }
    }
  }
}

=head2 add_forced_bin

  Title    : add_forced_bins
  Usage    : $data->add_forced_bins(
               bin => 'synapr',
               file_name => 'forcedbins.txt'
             );
  Function : Adds a parsed BLASTN file that has forced all reads into a single bin to the $self->{reads} hash
  Args     : bin: Bin that is being forced
             file_name: File name of BLASTN file

=cut

sub add_forced_bin {
  my $self = shift;
  my %params = @_;
  my %reads;
  if (defined $params{bin} && defined $params{file_name}) {
    %reads = %{$self->_parse_metablast(file_name => $params{file_name})};
    foreach my $id (keys %reads) {
      $self->{forced}{$params{bin}}{$id} = $reads{$id};
    }
  }
}

=head2 add_metablast

=cut

sub add_metablast {
  my $self = shift;
  my %params = @_;
  if (defined $params{file_name}) {
    if (defined $params{tag}) {
      my %reads = %{$self->_parse_metablast (file_name => $params{file_name})};
      my $tag = $params{tag};
      $self->{$tag} = \%reads;
    }
    else {
      my %reads = (
        %{$self->{reads}},
        %{$self->_parse_metablast (file_name => $params{file_name})}
      );
      $self->{reads} = \%reads;
    }
  }
}

=head2 add_metagenome

  Title    : add_metagenome
  Usage    : $data->add_metagenome (
               file_name => 'metagenome.fasta'
             );
  Function : Adds a metagenome file to the data of this object.
  Args     : file_name: Metagenome fasta file

=cut

sub add_metagenome {
  my $self = shift;
  my %params = @_;
  if (defined $params{file_name}) {
    $self->_parse_metagenome(%params);
    $self->_add_metagenome_info();
  }
}

=head2 add_assembly

  Title    : add_assembly
  Usage    : $data->add_assembly (
               file_name => 'assembly.txt'
             );
  Function : Adds an assembly file to the data of this object.
  Args     : name: Name of this Assembly} 
             assembly_file: Assembly file
             size_file: Assembly size file
             gene_file: Assembly gene file

=cut

sub add_assembly {
  my $self = shift;
  my %params = @_;
  if (defined $params{name} && defined $params{assembly_file} && defined $params{size_file} && defined $params{gene_file}) {
    my $assembly = new Pigeon::Data::Assembly(
      name          => $params{name}, 
      assembly_file => $params{assembly_file},
      size_file     => $params{size_file},
      gene_file     => $params{gene_file}
    );
    $self->{assembly}{$params{name}} = $assembly;
    return $assembly;
  }
}

=head2 add_pca

  Title    : add_pca
  Usage    : my %pca = $data->add_pca(
               file_name => 'data.pca'
             );
  Function : Imports a Principal Component Analysis file generated with R,
             and returns a hash containing the data.
  Returns  : Hash containing the PCA data
  Args     : name: name of this PCA
             file_name: File name of PCA data to load
             dimensions: Number of dimensions to import
             
=cut

sub add_pca {
  my $self = shift;
  my %params = @_;
  if (defined $params{name} && defined $params{file_name} && defined $params{dimensions}) {
    my $pca = new Pigeon::Data::PCA (
      name       => $params{name},
      file_name  => $params{file_name},
      dimensions => $params{dimensions}
    );
    $self->{pca}{$params{name}} = $pca;
    return $pca;
  }
}

=head2 add_ocounts

  Title    : add_ocounts
  Usage    : my %ocounts = $data->add_ocounts(
               file_name => 'data.txt'
             );
  Function : Imports a matrix of oligonucleotide frequency counts generated with TETRA,
             and returns a hash containing the data.
  Returns  : Hash containing the oligocount data
  Args     : file_name: File name of oligocount data to load
             
=cut

sub add_ocounts {
  my $self = shift;
  my %params = @_;
  if (defined $params{name} && defined $params{file_name}) {
    my $ocount = new Pigeon::Data::Ocount (
      name       => $params{name},
      file_name  => $params{file_name},
    );
    $self->{ocount}{$params{name}} = $ocount;
    return $ocount;
  }
}

=head2 add_threeD

  Title    : add_threeD
  Usage    : my %threeD = $data->add_threeD(
               file_name => 'data.threeD'
             );
  Function : Imports a Principal Component Analysis file generated with R,
             and returns a hash containing the data.
  Returns  : Hash containing the threeD data
  Args     : name: name of this threeD
             file_name: File name of threeD data to load
             dimensions: Number of dimensions to import
             
=cut

sub add_threeD {
  my $self = shift;
  my %params = @_;
  if (defined $params{name} && defined $params{file_name}) {
    my $threeD = new Pigeon::Data::PCA (
      name       => $params{name},
      file_name  => $params{file_name},
      dimensions => 3,
      threeD	 => 'yes'
    );
    $self->{threeD}{$params{name}} = $threeD;
    return $threeD;
  }
}

=head2 add_cluster

  Title    : add_cluster
  Usage    : $data->add_cluster(
               k   => 15,
               pca_name => 'pca_id'
             );
                  -OR-
             $data->add_cluster(
               k   => 15,
               oligo_name => 'oligo_id'
             );
  Function : Runs the clustering algorithm on PCA or oligocount data using the given k
  Args     : k: Number of clusters to create (not necessary when used with 'threeD_name')
             pca_name: PCA data to cluster
                    -OR-
             oligo_name: Oligocount data to cluster
                    -OR-
             threeD_name: Scatterplot 3D data to cluster

=cut

sub add_cluster {
  my $self = shift;
  my %params = @_;
  my $vertices;
  my $name;
  my $cluster;

  if (defined $params{pca_name}) {
    $vertices = $self->{pca}{$params{pca_name}}->vertices();
    $name = $params{pca_name};
  }
  elsif (defined $params{oligo_name}) {
    $vertices = $self->{ocount}{$params{oligo_name}}->vertices();
    $name = $params{oligo_name};
  }
  elsif (defined $params{threeD_name}) {
    $vertices = $self->{threeD}{$params{threeD_name}}->vertices();
    $name = $params{threeD_name};
  }

  if (defined $params{algorithm} && $params{algorithm} eq 'gmeans') {
    $cluster = new Pigeon::Cluster (
      algorithm  => $params{algorithm},
      vertices   => $vertices
    );
  }
  else {
    $cluster = new Pigeon::Cluster (
      algorithm  => $params{algorithm},
      k          => $params{k},
      vertices   => $vertices
    );
  }

  if (defined $params{k}) {
    push (@{$self->{cluster}{$name}->[$params{k}]}, $cluster);
  }
  else {
    push (@{$self->{cluster}{$name}->[0]}, $cluster);
  }

  return $cluster;
}

=head2 parse_bin

  Title    : parse_bin
  Usage    : my $bin = $data->parse_bin('ctg');
  Function : Creates easy to read bin names based on the raw bin provided
  Returns  : String containing easy to read bin
  Args     : bin: Raw bin

=cut

sub parse_bin {
  my $self = shift;
  my %params = @_;
  my $bin;
  if (defined $params{bin}) {
    $bin = $params{bin};
  }
  else {
    return 'null';
  }
  if ($bin =~ /ctg/) {
    $bin = "acidobacteria_bacterium";
  }
  elsif ($bin =~ /ntds/) {
    $bin = "desulfovibrio_desulfuricans";
  }
  elsif ($bin =~ /ntaa/) {
    $bin = "aquifex_aeolicus_vf5";
  }
  elsif ($bin =~ /gch/) {
    $bin = "carboxydothermus_hydrogenoformans_z-2901";
  }
  elsif ($bin =~ /gct/) {
    $bin = "chlorobium_tepidum";
  }
  elsif ($bin =~ /nc_011026\.1/) {
    $bin = "chloroherpeton_thalassium" ;
  }
  elsif ($bin =~ /nc_003240\.1/ || $bin =~ /nc_003267\.1/ || $bin =~ /nc_003270\.1/ ||  $bin =~/nc_003272\.1/ || $bin =~ /nc_003273\.1/ || $bin =~ /nc_003276\.1/) {
    $bin = "nostoc_sp._pcc_7120" ;
  }
  elsif ($bin =~ /ntmt/) {
    $bin = "methanothermobacter_thermautotrophicus_str._delta_h";
  }
  elsif ($bin =~ /ntst/) {
    $bin = "symbiobacterium_thermophilum";
  }
  elsif ($bin =~ /gyma/ || $bin =~ /nc_007775\.1/) {
    $bin = "synechococcus_sp._os-type_a_strain";
  }
  elsif ($bin =~ /gymb/ || $bin =~ /nc_007776\.1/) {
    $bin = "synechococcus_sp._os-type_b'_strain";
  }
  elsif ($bin =~ /nttt01/) {
    $bin = "thermoanaerobacter_tengcongensis";
  }
  elsif ($bin =~ /nttt02/) {
    $bin = "thermus_thermophilus_hb27";
  }
  elsif ($bin =~ /nttt03/) {
    $bin = "thermus_thermophilus_hb8";
  }
  elsif ($bin =~ /ntte/ || $bin =~ /thermosynechococcus_elongatus_pcc_7942/ || $bin =~ /nc_004113\.1/) {
    $bin = "thermosynechococcus_elongatus_bp-1";
  }
  elsif ($bin =~ /btm/) {
    $bin = "thermotoga_maritima";
  }
  elsif ($bin =~ /ggo/) {
    $bin = "gemmata_obscuriglobus";
  }
  elsif ($bin =~ /gha/) {
    $bin = "haloferax_volcanii";
  }
  elsif ($bin =~ /gtc/) {
    $bin = "thermodesulfobacterium_commune_dsm_2718";
  }
  elsif ($bin =~ /gty/ || $bin =~ /nc_011296\.1/) {
    $bin = "thermodesulfovibrio_yellowstonii";
  }
  elsif ($bin =~ /gtr/ || $bin =~ /nc_011959\.1/ || $bin =~ /nc_011961\.1/) {
    $bin = "thermomicrobium_roseum";
  }
  elsif ($bin =~ /csac/ || $bin =~ /gcsb/) {
    $bin = "caldicellulosiruptor_saccharolyticus";
  }
  elsif ($bin =~ /4000861/ || $bin =~ /ntca02/ || $bin =~ /nc_012032\.1/) {
    $bin = "chloroflexus_sp._y-400-fl";
  }
  elsif ($bin =~ /3635487/) {
    $bin = "thermoanaerobacter_ethanolicus_atcc_33223";
  }
  elsif ($bin =~ /1099505/) {
    $bin = 'gfp';
  }
  elsif ($bin =~ /contig169/ || $bin =~ /4000376/ || $bin =~ /nc_009523\.1/) {
    $bin = "roseiflexus_sp._rs1";
  }
  elsif ($bin =~ /nc_009767\.1/) {
    $bin = "roseiflexus_castenholzii_hlo8";
  }
  elsif ($bin =~ /nc_009972\.1/ || $bin =~ /nc_009973\.1/ || $bin =~ /nc_009974\.1/) {
    $bin = "herpetosiphon_aurantiacus_atcc_23779";
  }
  elsif ($bin =~ /nc_011004\.1/) {
    $bin = "rhodopseudomonas_palustris_tie-1";
  }
  # Mel's gene metagenome
  elsif ($bin =~ /^apcab_m60/) {
    $bin = 'apcab_m60c';
  }
  elsif ($bin =~ /^apcab_m65/) {
    $bin = 'apcab_m65c';
  }
  elsif ($bin =~ /^aroa_m60/) {
    $bin = 'aroa_m60c';
  }
  elsif ($bin =~ /^aroa_m65/) {
    $bin = 'aroa_m65c';
  }
  elsif ($bin =~ /^rbsk_m60/) {
    $bin = 'rbsk_m60c';
  }
  elsif ($bin =~ /^rbsk_m65/) {
    $bin = 'rbsk_m65c';
  }
  elsif ($bin =~ /ftsmq7y02/) {
    $bin = "synechococcus_sp._os-type_a'_strain";
  }
  elsif ($bin =~ /^(cluster\d+)_.*/) {
    $bin = $1;
  }
  return $bin;
}

=head2 _parse_metagenome

  Title    : _parse_metagenome
  Usage    : private
  Function : Opens the metagenome file and stores each sequence in the hash $self->{reads}{id}{sequence}.
  Args     : file_name: File name of the metagenome to parse

=cut

sub _parse_metagenome {
  my $self = shift;
  my %params = @_;
  my $id = 'null';
  my ($sequence, $mate, $source);
  my (%clone_ids, %definitions);
  if (defined $params{file_name} && -e $params{file_name}) {
    open (FILE, $params{file_name}) or die "Can't open metagenome file " . $params{file_name} . ": " . $! . "\n";
    while (my $line = <FILE>) {
      $line =~ s/[\n\r]//g;
      $line = lc $line;
      if ($line =~ /^>/) {
        if ($id ne 'null') {
          $self->{reads}{$id}{clone_pair} = $mate;
#          $self->{reads}{$id}{sequence} = $sequence;
          $self->{reads}{$id}{source} = $source;
          foreach my $def (keys %definitions) {
            $self->{reads}{$id}{definitions}{$def} = $definitions{$def};
          }
          $sequence = '';
          %definitions = ();
        }
        ($id, my $definition) = split (/\s+/, $line, 2);
        # Remove extra characters from id string.
        if ($id =~ />lcl\|/ || $id =~ />gnl\|/) {
          ($_, $id, $_) = split (/\|/, $id, 3);
        }
        else {
          substr ($id, 0, 1) = ""
        }
        # Parse definition line.
        if (defined $definition && $definition =~ /[\\|\/]?\S+=\S+/) {
          my @defs = split (/\s+[\/|\\]?/, $definition);
          foreach my $def (@defs) {
            if ($def =~ /[\\|\/]?(\S+)=(\S+)/) {
              $definitions{$1} = $2;
            }
          }
        }
        if (defined $definitions{mate}) {
          $mate = $definitions{mate};
        }
        else {
          $mate = 'null';
        }
        if (defined $definitions{clone_insert_id}) {
          push (@{$clone_ids{$definitions{clone_insert_id}}}, $id);
        }
        if (defined $definitions{src}) {
          $source = $definitions{src};
        }
        elsif (defined $definitions{library_name}) {
          $source = $definitions{library_name};
        }
        else {
          $source = 'null';
        }
      }
      else {
        $sequence .= $line;
      }
    }
    close (FILE);
    # Add the last sequence
    if ($id ne 'null' && $sequence ne '') {
      $self->{reads}{$id}{clone_pair} = $mate;
#      $self->{reads}{$id}{sequence} = $sequence;
      $self->{reads}{$id}{source} = $source;
      foreach my $def (keys %definitions) {
        $self->{reads}{$id}{definitions}{$def} = $definitions{$def};
      }
    }
    # For reads with a clone_insert_id, set clone_pair
    foreach my $clone (keys %clone_ids) {
      my @ids = @{$clone_ids{$clone}};
      if (@ids == 2 && defined $self->{reads}{$ids[0]} && defined $self->{reads}{$ids[1]}) {
        $self->{reads}{$ids[0]}{clone_pair} = $ids[1];
        $self->{reads}{$ids[1]}{clone_pair} = $ids[0];
      }
    }
  }
}

=head2 _parse_metablast

  Title    : _parse_metablast
  Usage    : private
  Function : Opens the provided metablast file and stores each line of data in the hash $self->{reads}{id}{}
             Each line of data in the meta_blast file stores the variables:  id, length, bin, 
             start_query, stop_query, start_subject, stop_subject, percent_id, percent_similarity,
             strand_query, strand_subject, score, and e_value.
  Returns  : Hash containing the reads
  Args     : file_name: File name of the netablast file to parse

=cut

sub _parse_metablast {
  my $self = shift;
  my %params = @_;
  my %reads;
  if (defined $params{file_name} && -e $params{file_name}) {
    open (FILE, $params{file_name}) or die "Can't open metablast file " . $params{file_name} . ": " . $! . "\n";
    while (my $line = <FILE>) {
      # Split variables apart, tab delimited
      $line =~ s/[\n\r]//g;
      $line = lc $line;
      (my $id, $_, $line) =  split("\t", $line, 3);
      my $clone_id;
      if (substr($id,0,4) eq 'lcl|' || substr($id,0,4) eq 'gnl|') {
        ($_, $id, $_) = split (/\|/, $id);
      }
      if (defined $id) {
        ($reads{$id}{length},$_, $_,
         $reads{$id}{bin},
         $reads{$id}{query_start},
         $reads{$id}{query_end},
         $reads{$id}{subject_start},
         $reads{$id}{subject_end},
         $reads{$id}{percent_identity},
         $reads{$id}{percent_similarity},
         $reads{$id}{score},
         $_, $_, $_, $_,
         $reads{$id}{query_strand},
         $reads{$id}{subject_strand},
         $reads{$id}{e_value}, $_) = split("\t", $line);
        # Make sure each bin and contig has the proper format
        $reads{$id}{bin} = lc($reads{$id}{bin});
        if (substr($reads{$id}{bin},0,4) eq 'gnl|' || substr($reads{$id}{bin},0,4) eq 'lcl|' || substr($reads{$id}{bin},0,4) eq 'ref|') {
          ($_, $reads{$id}{bin}, $reads{$id}{contig}) = split (/\|/, $reads{$id}{bin});
        }
        if (not defined $reads{$id}{contig}) {
          $reads{$id}{contig} = 'null';
        }
        $reads{$id}{bin} = $self->parse_bin(bin => $reads{$id}{bin});
        # Make sure strands have the proper format.
        if (lc ($reads{$id}{query_strand}) eq 'minus') {
          $reads{$id}{query_strand} = -1;
        }
        elsif (lc ($reads{$id}{query_strand}) eq 'plus') {
          $reads{$id}{query_strand} = 1;
        }
        if (lc ($reads{$id}{subject_strand}) eq 'minus') {
          $reads{$id}{subject_strand} = -1;
        }
        elsif (lc ($reads{$id}{subject_strand}) eq 'plus') {
          $reads{$id}{subject_strand} = 1;
        }
        # If read falls into null bin, give default values.
        if ($reads{$id}{bin} eq 'null') {
          $reads{$id}{length} = 0;
          $reads{$id}{query_start} = 0;
          $reads{$id}{query_end} = 0;
          $reads{$id}{subject_start} = 0;
          $reads{$id}{subject_end} = 0;
          $reads{$id}{percent_identity} = 0;
          $reads{$id}{percent_similarity} = 0;
          $reads{$id}{score} = 0;
          $reads{$id}{query_strand} = 0;
          $reads{$id}{subject_strand} = 0;
          $reads{$id}{e_value} = $int_max;
        } 
      }
    }
    close FILE;
  }
  return \%reads;
}

=head2 _add_metagenome_info

  Title    : _add_metagenome_info
  Usage    : private
  Function : Adds information about the metagenome for each read.

=cut

sub _add_metagenome_info {
  my $self = shift;
  foreach my $id (keys %{$self->{reads}}) {
    # BAC Metagenomes
    if (defined $self->{reads}{$id}{source} && $self->{reads}{$id}{source} eq '01-b-yellow-01') {
      $self->{reads}{$id}{metagenome} = 'mslow';
      $self->{reads}{$id}{location} = 'Mushroom Spring';
      $self->{reads}{$id}{temperature} = '60C';
      $self->{reads}{$id}{layer} = 'top 1mm, green';
      $self->{reads}{$id}{size} = '130-130 kb';
      $self->{reads}{$id}{extracted} = 'Amplicon';
    }
    if (defined $self->{reads}{$id}{source} && $self->{reads}{$id}{source} eq 'm60bacends') {
      $self->{reads}{$id}{metagenome} = 'mslow';
      $self->{reads}{$id}{location} = 'Mushroom Spring';
      $self->{reads}{$id}{temperature} = '60C';
      $self->{reads}{$id}{layer} = 'top 1mm, green';
      $self->{reads}{$id}{size} = '180-120 kb';
      $self->{reads}{$id}{extracted} = 'Amplicon';
    }
    if (defined $self->{reads}{$id}{source} && $self->{reads}{$id}{source} eq 'cyanobac-b-01-90-100kb') {
      $self->{reads}{$id}{metagenome} = 'mslow';
      $self->{reads}{$id}{location} = 'Mushroom Spring';
      $self->{reads}{$id}{temperature} = '60C';
      $self->{reads}{$id}{layer} = 'top 1mm, green';
      $self->{reads}{$id}{size} = '90-100 kb';
      $self->{reads}{$id}{extracted} = 'Amplicon';
    }
    if (defined $self->{reads}{$id}{source} && $self->{reads}{$id}{source} eq 'cyanmetag-b-01-200-201kb') {
      $self->{reads}{$id}{metagenome} = 'mshigh';
      $self->{reads}{$id}{location} = 'Mushroom Spring';
      $self->{reads}{$id}{temperature} = '65C';
      $self->{reads}{$id}{layer} = 'top 1mm, green';
      $self->{reads}{$id}{size} = '200-201 kb';
      $self->{reads}{$id}{extracted} = 'Amplicon';
    }
    if (defined $self->{reads}{$id}{source} && $self->{reads}{$id}{source} eq 'synechoc-b-02-100-101kb') {
      $self->{reads}{$id}{metagenome} = 'mslow';
      $self->{reads}{$id}{location} = 'Mushroom Spring';
      $self->{reads}{$id}{temperature} = '60C';
      $self->{reads}{$id}{layer} = 'top 1mm, green';
      $self->{reads}{$id}{size} = '100-101 kb';
      $self->{reads}{$id}{extracted} = 'Amplicon';
    }
    if (defined $self->{reads}{$id}{source} && $self->{reads}{$id}{source} eq 'synechoc-b-01-100-101kb') {
      $self->{reads}{$id}{metagenome} = 'mshigh';
      $self->{reads}{$id}{location} = 'Mushroom Spring';
      $self->{reads}{$id}{temperature} = '65C';
      $self->{reads}{$id}{layer} = 'top 1mm, green';
      $self->{reads}{$id}{size} = '100-101 kb';
      $self->{reads}{$id}{extracted} = 'Amplicon';
    }
    # XXX mystery metagenome library?
    if (defined $self->{reads}{$id}{source} && $self->{reads}{$id}{source} eq 'synechoc-b-01-200-201kb') {
      $self->{reads}{$id}{metagenome} = 'mshigh';
      $self->{reads}{$id}{location} = 'Mushroom Spring';
      $self->{reads}{$id}{temperature} = '65C';
      $self->{reads}{$id}{layer} = 'top 1mm, green';
      $self->{reads}{$id}{size} = '200-201 kb';
      $self->{reads}{$id}{extracted} = 'Amplicon';
    }
    # Mel's gene metagenomes
    if (defined $self->{reads}{$id}{source} && $self->{reads}{$id}{source} =~ /m6065apcabsynaalldata/) {
      $self->{reads}{$id}{metagenome} = 'apcab';
      $self->{reads}{$id}{location} = 'Mushroom Spring';
      $self->{reads}{$id}{temperature} = '60-65C';
      $self->{reads}{$id}{layer} = 'unknown';
      $self->{reads}{$id}{size} = '0.39-0.44 kb';
      $self->{reads}{$id}{extracted} = 'unknown';
    }
    if (defined $self->{reads}{$id}{source} && $self->{reads}{$id}{source} =~ /m6065aroasynanoapr220nt59/) {
      $self->{reads}{$id}{metagenome} = 'aroa';
      $self->{reads}{$id}{location} = 'Mushroom Spring';
      $self->{reads}{$id}{temperature} = '60-65C';
      $self->{reads}{$id}{layer} = 'unknown';
      $self->{reads}{$id}{size} = '0.21-0.22 kb';
      $self->{reads}{$id}{extracted} = 'unknown';
    }
    if (defined $self->{reads}{$id}{source} && $self->{reads}{$id}{source} =~ /m6065rbsksyna/) {
      $self->{reads}{$id}{metagenome} = 'rbsk';
      $self->{reads}{$id}{location} = 'Mushroom Spring';
      $self->{reads}{$id}{temperature} = '60-65C';
      $self->{reads}{$id}{layer} = 'unknown';
      $self->{reads}{$id}{size} = '0.60-0.62 kb';
      $self->{reads}{$id}{extracted} = 'unknown';
    }
    if (defined $self->{reads}{$id}{source} && $self->{reads}{$id}{source} =~ /apcab_syna/) {
      $self->{reads}{$id}{metagenome} = 'apcAB_syna';
      $self->{reads}{$id}{location} = 'Mushroom Spring';
      $self->{reads}{$id}{temperature} = '60-65C';
      $self->{reads}{$id}{layer} = 'unknown';
      $self->{reads}{$id}{size} = '0.39-0.44 kb';
      $self->{reads}{$id}{extracted} = 'unknown';
    }
    if (defined $self->{reads}{$id}{source} && $self->{reads}{$id}{source} =~ /apcab_synbpr/) {
      $self->{reads}{$id}{metagenome} = 'apcAB_synbpr';
      $self->{reads}{$id}{location} = 'Mushroom Spring';
      $self->{reads}{$id}{temperature} = '60-65C';
      $self->{reads}{$id}{layer} = 'unknown';
      $self->{reads}{$id}{size} = '0.39-0.44 kb';
      $self->{reads}{$id}{extracted} = 'unknown';
    }
    if (defined $self->{reads}{$id}{source} && $self->{reads}{$id}{source} =~ /apcab_m60c/) {
      $self->{reads}{$id}{metagenome} = 'apcAB_m60c';
      $self->{reads}{$id}{location} = 'Mushroom Spring';
      $self->{reads}{$id}{temperature} = '60C';
      $self->{reads}{$id}{layer} = 'unknown';
      $self->{reads}{$id}{size} = '0.39-0.44 kb';
      $self->{reads}{$id}{extracted} = 'unknown';
    }
    if (defined $self->{reads}{$id}{source} && $self->{reads}{$id}{source} =~ /apcab_m65c/) {
      $self->{reads}{$id}{metagenome} = 'apcAB_m65c';
      $self->{reads}{$id}{location} = 'Mushroom Spring';
      $self->{reads}{$id}{temperature} = '65C';
      $self->{reads}{$id}{layer} = 'unknown';
      $self->{reads}{$id}{size} = '0.39-0.44 kb';
      $self->{reads}{$id}{extracted} = 'unknown';
    }
    if (defined $self->{reads}{$id}{source} && $self->{reads}{$id}{source} =~ /aroa_syna/) {
      $self->{reads}{$id}{metagenome} = 'aroA_syna';
      $self->{reads}{$id}{location} = 'Mushroom Spring';
      $self->{reads}{$id}{temperature} = '60-65C';
      $self->{reads}{$id}{layer} = 'unknown';
      $self->{reads}{$id}{size} = '0.21-0.22 kb';
      $self->{reads}{$id}{extracted} = 'unknown';
    }
    if (defined $self->{reads}{$id}{source} && $self->{reads}{$id}{source} =~ /aroa_synbpr/) {
      $self->{reads}{$id}{metagenome} = 'aroA_synbpr';
      $self->{reads}{$id}{location} = 'Mushroom Spring';
      $self->{reads}{$id}{temperature} = '60-65C';
      $self->{reads}{$id}{layer} = 'unknown';
      $self->{reads}{$id}{size} = '0.21-0.22 kb';
      $self->{reads}{$id}{extracted} = 'unknown';
    }
   if (defined $self->{reads}{$id}{source} && $self->{reads}{$id}{source} =~ /aroa_m60c/) {
      $self->{reads}{$id}{metagenome} = 'aroA_m60c';
      $self->{reads}{$id}{location} = 'Mushroom Spring';
      $self->{reads}{$id}{temperature} = '60C';
      $self->{reads}{$id}{layer} = 'unknown';
      $self->{reads}{$id}{size} = '0.21-0.22 kb';
      $self->{reads}{$id}{extracted} = 'unknown';
    }
    if (defined $self->{reads}{$id}{source} && $self->{reads}{$id}{source} =~ /aroa_m65c/) {
      $self->{reads}{$id}{metagenome} = 'aroA_m65c';
      $self->{reads}{$id}{location} = 'Mushroom Spring';
      $self->{reads}{$id}{temperature} = '65C';
      $self->{reads}{$id}{layer} = 'unknown';
      $self->{reads}{$id}{size} = '0.21-0.22 kb';
      $self->{reads}{$id}{extracted} = 'unknown';
    }
    if (defined $self->{reads}{$id}{source} && $self->{reads}{$id}{source} =~ /rbsk_syna/) {
      $self->{reads}{$id}{metagenome} = 'rbsK_syna';
      $self->{reads}{$id}{location} = 'Mushroom Spring';
      $self->{reads}{$id}{temperature} = '60-65C';
      $self->{reads}{$id}{layer} = 'unknown';
      $self->{reads}{$id}{size} = '0.60-0.62 kb';
      $self->{reads}{$id}{extracted} = 'unknown';
    }
    if (defined $self->{reads}{$id}{source} && $self->{reads}{$id}{source} =~ /rbsk_synbpr/) {
      $self->{reads}{$id}{metagenome} = 'rbsK_synbpr';
      $self->{reads}{$id}{location} = 'Mushroom Spring';
      $self->{reads}{$id}{temperature} = '60-65C';
      $self->{reads}{$id}{layer} = 'unknown';
      $self->{reads}{$id}{size} = '0.60-0.62 kb';
      $self->{reads}{$id}{extracted} = 'unknown';
    }
    if (defined $self->{reads}{$id}{source} && $self->{reads}{$id}{source} =~ /rbsk_m60c/) {
      $self->{reads}{$id}{metagenome} = 'rbsK_m60c';
      $self->{reads}{$id}{location} = 'Mushroom Spring';
      $self->{reads}{$id}{temperature} = '60C';
      $self->{reads}{$id}{layer} = 'unknown';
      $self->{reads}{$id}{size} = '0.60-0.62 kb';
      $self->{reads}{$id}{extracted} = 'unknown';
    }
    if (defined $self->{reads}{$id}{source} && $self->{reads}{$id}{source} =~ /rbsk_m65c/) {
      $self->{reads}{$id}{metagenome} = 'rbsK_m65c';
      $self->{reads}{$id}{location} = 'Mushroom Spring';
      $self->{reads}{$id}{temperature} = '65C';
      $self->{reads}{$id}{layer} = 'unknown';
      $self->{reads}{$id}{size} = '0.60-0.62 kb';
      $self->{reads}{$id}{extracted} = 'unknown';
    }
    # FIBR Metagenomes
    if (defined $self->{reads}{$id}{source} && $self->{reads}{$id}{source} eq 'fibrcym') {
      $self->{reads}{$id}{metagenome} = 'oshigh';
      $self->{reads}{$id}{location} = 'Octopus Spring';
      $self->{reads}{$id}{temperature} = 'High';
      $self->{reads}{$id}{layer} = 'top 1mm, green';
      $self->{reads}{$id}{size} = '2-3 kb';
      $self->{reads}{$id}{extracted} = 'MSU';
    }
    if (defined $self->{reads}{$id}{source} && $self->{reads}{$id}{source} eq 'fibrcyn') {
      $self->{reads}{$id}{metagenome} = 'oshigh';
      $self->{reads}{$id}{location} = 'Octopus Spring';
      $self->{reads}{$id}{temperature} = 'High';
      $self->{reads}{$id}{layer} = 'top 1mm, green';
      $self->{reads}{$id}{size} = '10-12 kb';
      $self->{reads}{$id}{extracted} = 'MSU';
    }
    if (defined $self->{reads}{$id}{source} && $self->{reads}{$id}{source} eq 'fibrcyo') {
      $self->{reads}{$id}{metagenome} = 'oslow';
      $self->{reads}{$id}{location} = 'Octopus Spring';
      $self->{reads}{$id}{temperature} = 'Low';
      $self->{reads}{$id}{layer} = 'top 1mm, green';
      $self->{reads}{$id}{size} = '2-3 kb';
      $self->{reads}{$id}{extracted} = 'MSU';
    }
    if (defined $self->{reads}{$id}{source} && $self->{reads}{$id}{source} eq 'fibrcyp') {
      $self->{reads}{$id}{metagenome} = 'oslow';
      $self->{reads}{$id}{location} = 'Octopus Spring';
      $self->{reads}{$id}{temperature} = 'Low';
      $self->{reads}{$id}{layer} = 'top 1mm, green';
      $self->{reads}{$id}{size} = '10-12 kb';
      $self->{reads}{$id}{extracted} = 'MSU';
    }
    if (defined $self->{reads}{$id}{source} && $self->{reads}{$id}{source} eq 'fibrgym') {
      $self->{reads}{$id}{metagenome} = 'mslow';
      $self->{reads}{$id}{location} = 'Mushroom Spring';
      $self->{reads}{$id}{temperature} = '60C';
      $self->{reads}{$id}{layer} = 'top 1mm, green';
      $self->{reads}{$id}{size} = '2-3 kb';
      $self->{reads}{$id}{extracted} = 'TIGR';
    }
    if (defined $self->{reads}{$id}{source} && $self->{reads}{$id}{source} eq 'fibrgyn') {
      $self->{reads}{$id}{metagenome} = 'mslow';
      $self->{reads}{$id}{location} = 'Mushroom Spring';
      $self->{reads}{$id}{temperature} = '60C';
      $self->{reads}{$id}{layer} = 'top 1mm, green';
      $self->{reads}{$id}{size} = '10-12 kb';
      $self->{reads}{$id}{extracted} = 'TIGR';
    }
    if (defined $self->{reads}{$id}{source} && $self->{reads}{$id}{source} eq 'fibrgyo') {
      $self->{reads}{$id}{metagenome} = 'mslow';
      $self->{reads}{$id}{location} = 'Mushroom Spring';
      $self->{reads}{$id}{temperature} = '60C';
      $self->{reads}{$id}{layer} = '1mm below top';
      $self->{reads}{$id}{size} = '3-4 kb';
      $self->{reads}{$id}{extracted} = 'TIGR';
    }
    if (defined $self->{reads}{$id}{source} && $self->{reads}{$id}{source} eq 'fibrgyp') {
      $self->{reads}{$id}{metagenome} = 'mslow';
      $self->{reads}{$id}{location} = 'Mushroom Spring';
      $self->{reads}{$id}{temperature} = '60C';
      $self->{reads}{$id}{layer} = '1mm below top';
      $self->{reads}{$id}{size} = '5-6 kb';
      $self->{reads}{$id}{extracted} = 'TIGR';
    }
    if (defined $self->{reads}{$id}{source} && $self->{reads}{$id}{source} eq 'fibrgyq') {
      $self->{reads}{$id}{metagenome} = 'mslow';
      $self->{reads}{$id}{location} = 'Mushroom Spring';
      $self->{reads}{$id}{temperature} = '60C';
      $self->{reads}{$id}{layer} = 'bottom 1mm';
      $self->{reads}{$id}{size} = '4-5 kb';
      $self->{reads}{$id}{extracted} = 'TIGR';
    }
    if (defined $self->{reads}{$id}{source} && $self->{reads}{$id}{source} eq 'fibrymi') {
      $self->{reads}{$id}{metagenome} = 'mslow';
      $self->{reads}{$id}{location} = 'Mushroom Spring';
      $self->{reads}{$id}{temperature} = '60C';
      $self->{reads}{$id}{layer} = 'top 1mm, green';
      $self->{reads}{$id}{size} = '2-3 kb';
      $self->{reads}{$id}{extracted} = 'MSU';
    }
    if (defined $self->{reads}{$id}{source} && $self->{reads}{$id}{source} eq 'fibrymj') {
      $self->{reads}{$id}{metagenome} = 'mslow';
      $self->{reads}{$id}{location} = 'Mushroom Spring';
      $self->{reads}{$id}{temperature} = '60C';
      $self->{reads}{$id}{layer} = 'top 1mm, green';
      $self->{reads}{$id}{size} = '10-12 kb';
      $self->{reads}{$id}{extracted} = 'MSU';
    }
    if (defined $self->{reads}{$id}{source} && $self->{reads}{$id}{source} eq 'fibrgyr') {
      $self->{reads}{$id}{metagenome} = 'mshigh';
      $self->{reads}{$id}{location} = 'Mushroom Spring';
      $self->{reads}{$id}{temperature} = '65C';
      $self->{reads}{$id}{layer} = 'top 1mm, green';
      $self->{reads}{$id}{size} = '3-4 kb';
      $self->{reads}{$id}{extracted} = 'TIGR';
    }
    if (defined $self->{reads}{$id}{source} && $self->{reads}{$id}{source} eq 'fibrgys') {
      $self->{reads}{$id}{metagenome} = 'mshigh';
      $self->{reads}{$id}{location} = 'Mushroom Spring';
      $self->{reads}{$id}{temperature} = '65C';
      $self->{reads}{$id}{layer} = 'top 1mm, green';
      $self->{reads}{$id}{size} = '5-6 kb';
      $self->{reads}{$id}{extracted} = 'TIGR';
    }
    if (defined $self->{reads}{$id}{source} && $self->{reads}{$id}{source} eq 'fibrgyt') {
      $self->{reads}{$id}{metagenome} = 'mshigh';
      $self->{reads}{$id}{location} = 'Mushroom Spring';
      $self->{reads}{$id}{temperature} = '65C';
      $self->{reads}{$id}{layer} = '1mm below top';
      $self->{reads}{$id}{size} = '5-6 kb';
      $self->{reads}{$id}{extracted} = 'TIGR';
    }
    if (defined $self->{reads}{$id}{source} && $self->{reads}{$id}{source} eq 'fibrgyu') {
      $self->{reads}{$id}{metagenome} = 'mshigh';
      $self->{reads}{$id}{location} = 'Mushroom Spring';
      $self->{reads}{$id}{temperature} = '65C';
      $self->{reads}{$id}{layer} = 'bottom 1mm';
      $self->{reads}{$id}{size} = '5-6 kb';
      $self->{reads}{$id}{extracted} = 'TIGR';
    }
    if (defined $self->{reads}{$id}{source} && $self->{reads}{$id}{source} eq 'fibryma') {
      $self->{reads}{$id}{metagenome} = 'mshigh';
      $self->{reads}{$id}{location} = 'Mushroom Spring';
      $self->{reads}{$id}{temperature} = '65C';
      $self->{reads}{$id}{layer} = 'top 1mm, green';
      $self->{reads}{$id}{size} = '3-4 kb';
      $self->{reads}{$id}{extracted} = 'MSU';
     }
     if (defined $self->{reads}{$id}{source} && $self->{reads}{$id}{source} eq 'fibrymb') {
      $self->{reads}{$id}{metagenome} = 'mshigh';
      $self->{reads}{$id}{location} = 'Mushroom Spring';
      $self->{reads}{$id}{temperature} = '65C';
      $self->{reads}{$id}{layer} = 'top 1mm, green';
      $self->{reads}{$id}{size} = '8-9 kb';
      $self->{reads}{$id}{extracted} = 'MSU';
    }
    # RCN Metagenomes
    if (defined $self->{reads}{$id}{source} && $self->{reads}{$id}{source} eq 'rcn_site5_blvagreen') {
      $self->{reads}{$id}{metagenome} = 'site5';
      $self->{reads}{$id}{location} = 'Bath Lake Vista Annex Spring';
      $self->{reads}{$id}{datetime} = '2007-09-27 13:00:00';
      $self->{reads}{$id}{temperature} = '57.6C';
      $self->{reads}{$id}{dissolved_oxygen} = 0;
      $self->{reads}{$id}{dissolved_sulfide} = 117;
      $self->{reads}{$id}{ph} = 6.2;
      $self->{reads}{$id}{layer} = 'unknown';
      $self->{reads}{$id}{size} = '2-3 kb';
      $self->{reads}{$id}{extracted} = 'Chris Klatt';
    }
    if (defined $self->{reads}{$id}{source} && $self->{reads}{$id}{source} eq 'rcn_site6_wc') {
      $self->{reads}{$id}{metagenome} = 'site6';
      $self->{reads}{$id}{location} = 'White Creek';
      $self->{reads}{$id}{datetime} = '2007-09-15 15:00:00';
      $self->{reads}{$id}{temperature} = '50C';
      $self->{reads}{$id}{dissolved_oxygen} = 0;
      $self->{reads}{$id}{dissolved_sulfide} = 0;
      $self->{reads}{$id}{ph} = 0;
      $self->{reads}{$id}{layer} = 'unknown';
      $self->{reads}{$id}{size} = '2-3 kb';
      $self->{reads}{$id}{extracted} = 'Scott R. Miller';
    }
    if (defined $self->{reads}{$id}{source} && $self->{reads}{$id}{source} eq 'rcn_site7_cp') {
      $self->{reads}{$id}{metagenome} = 'site7';
      $self->{reads}{$id}{location} = 'Chocolate Pots';
      $self->{reads}{$id}{datetime} = 'unknown';
      $self->{reads}{$id}{temperature} = 'unknown';
      $self->{reads}{$id}{dissolved_oxygen} = 0;
      $self->{reads}{$id}{dissolved_sulfide} = 0;
      $self->{reads}{$id}{ph} = 0;
      $self->{reads}{$id}{layer} = 'unknown';
      $self->{reads}{$id}{size} = '2-3 kb';
      $self->{reads}{$id}{extracted} = 'Niki Parenteau';
    }
    if (defined $self->{reads}{$id}{source} && $self->{reads}{$id}{source} eq 'rcn_site15_ms60undermat') {
      $self->{reads}{$id}{metagenome} = 'site15';
      $self->{reads}{$id}{location} = 'Mushroom Spring';
      $self->{reads}{$id}{datetime} = '2007-12-13 13:00:00';
      $self->{reads}{$id}{temperature} = '59.9C';
      $self->{reads}{$id}{dissolved_oxygen} = 140.63;
      $self->{reads}{$id}{dissolved_sulfide} = 0;
      $self->{reads}{$id}{ph} = 8.2;
      $self->{reads}{$id}{layer} = 'unknown';
      $self->{reads}{$id}{size} = '2-3 kb';
      $self->{reads}{$id}{extracted} = 'Chris Klatt';
    }
    if (defined $self->{reads}{$id}{source} && $self->{reads}{$id}{source} eq 'rcn_site16_fg') {
      $self->{reads}{$id}{metagenome} = 'site16';
      $self->{reads}{$id}{location} = 'Fairy Geyser';
      $self->{reads}{$id}{datetime} = 'unknown';
      $self->{reads}{$id}{temperature} = 'unknown';
      $self->{reads}{$id}{dissolved_oxygen} = 0;
      $self->{reads}{$id}{dissolved_sulfide} = 0;
      $self->{reads}{$id}{ph} = 0;
      $self->{reads}{$id}{layer} = 'unknown';
      $self->{reads}{$id}{size} = '2-3 kb';
      $self->{reads}{$id}{extracted} = 'Sarah Boomer';
    }
    if (defined $self->{reads}{$id}{source} && $self->{reads}{$id}{source} eq 'rcn_site20_blvapurple') {
      $self->{reads}{$id}{metagenome} = 'site20';
      $self->{reads}{$id}{location} = 'Bath Lake Vista Annex Spring';
      $self->{reads}{$id}{datetime} = '2008-05-13 12:00:00';
      $self->{reads}{$id}{temperature} = '56C';
      $self->{reads}{$id}{dissolved_oxygen} = 0;
      $self->{reads}{$id}{dissolved_sulfide} = 0;
      $self->{reads}{$id}{ph} = 6.2;
      $self->{reads}{$id}{layer} = 'unknown';
      $self->{reads}{$id}{size} = '2-3 kb';
      $self->{reads}{$id}{extracted} = 'Zack Jay';
    }
    # In-Silico Digest Metagenomes
    if (defined $self->{reads}{$id}{source} && $self->{reads}{$id}{source} =~ /^digest_(\d+?)_(.*)/ ) {
      my $size = $1;
      #convert to kb
      $size = $size / 1000;
      my $upsize;
      if ($size >= 10) {
        $upsize = $size + 2;
      }
      else {
        $upsize = $size + 1;
      }
      my $genome = $2; 
      $self->{reads}{$id}{metagenome} = 'in_silico_digest_'.$genome;
      $self->{reads}{$id}{location} = 'in silico';
      $self->{reads}{$id}{datetime} = '';
      $self->{reads}{$id}{temperature} = '';
      $self->{reads}{$id}{dissolved_oxygen} = 0;
      $self->{reads}{$id}{dissolved_sulfide} = 0;
      $self->{reads}{$id}{ph} = '';
      $self->{reads}{$id}{layer} = 'unknown';
      $self->{reads}{$id}{size} = $size . "-" . $upsize . " kb";
#      $self->{reads}{$id}{size} = $size . "-" . $size . " kb";
      $self->{reads}{$id}{extracted} = 'computer';
    }
    # Titanium454 Metagenomes
    if (defined $self->{reads}{$id}{source} && $self->{reads}{$id}{source} eq 'mush60c') {
      $self->{reads}{$id}{metagenome} = 'mush60c';
      $self->{reads}{$id}{location} = 'Mushroom Spring';
      $self->{reads}{$id}{datetime} = '2008-10-28 09:27:00';
      $self->{reads}{$id}{temperature} = '58.9C';
      $self->{reads}{$id}{dissolved_oxygen} = 0;
      $self->{reads}{$id}{dissolved_sulfide} = 0;
      $self->{reads}{$id}{irradiance} = 124;
      $self->{reads}{$id}{ph} = 0;
      $self->{reads}{$id}{layer} = 'top 5mm';
      $self->{reads}{$id}{size} = 'unknown';
      $self->{reads}{$id}{extracted} = 'Chris Klatt';
    }
    if (defined $self->{reads}{$id}{source} && $self->{reads}{$id}{source} eq 'mush61c') {
      $self->{reads}{$id}{metagenome} = 'mush61c';
      $self->{reads}{$id}{location} = 'Mushroom Spring';
      $self->{reads}{$id}{datetime} = '2008-10-28 09:27:00';
      $self->{reads}{$id}{temperature} = '59.3C';
      $self->{reads}{$id}{dissolved_oxygen} = 0;
      $self->{reads}{$id}{dissolved_sulfide} = 0;
      $self->{reads}{$id}{irradiance} = 124;
      $self->{reads}{$id}{ph} = 0;
      $self->{reads}{$id}{layer} = 'top 5mm';
      $self->{reads}{$id}{size} = 'unknown';
      $self->{reads}{$id}{extracted} = 'Chris Klatt';
    }
    if (defined $self->{reads}{$id}{source} && $self->{reads}{$id}{source} eq 'mush62c') {
      $self->{reads}{$id}{metagenome} = 'mush62c';
      $self->{reads}{$id}{location} = 'Mushroom Spring';
      $self->{reads}{$id}{datetime} = '2008-10-28 09:21:00';
      $self->{reads}{$id}{temperature} = '59.4C';
      $self->{reads}{$id}{dissolved_oxygen} = 0;
      $self->{reads}{$id}{dissolved_sulfide} = 0;
      $self->{reads}{$id}{irradiance} = 124;
      $self->{reads}{$id}{ph} = 0;
      $self->{reads}{$id}{layer} = 'top 5mm';
      $self->{reads}{$id}{size} = 'unknown';
      $self->{reads}{$id}{extracted} = 'Chris Klatt';
    }
    if (defined $self->{reads}{$id}{source} && $self->{reads}{$id}{source} eq 'mush63c') {
      $self->{reads}{$id}{metagenome} = 'mush63c';
      $self->{reads}{$id}{location} = 'Mushroom Spring';
      $self->{reads}{$id}{datetime} = '2008-10-28 09:15:00';
      $self->{reads}{$id}{temperature} = '60.1C';
      $self->{reads}{$id}{dissolved_oxygen} = 0;
      $self->{reads}{$id}{dissolved_sulfide} = 0;
      $self->{reads}{$id}{irradiance} = 124;
      $self->{reads}{$id}{ph} = 0;
      $self->{reads}{$id}{layer} = 'top 5mm';
      $self->{reads}{$id}{size} = 'unknown';
      $self->{reads}{$id}{extracted} = 'Chris Klatt';
    }
    if (defined $self->{reads}{$id}{source} && $self->{reads}{$id}{source} eq 'mush64c') {
      $self->{reads}{$id}{metagenome} = 'mush64c';
      $self->{reads}{$id}{location} = 'Mushroom Spring';
       $self->{reads}{$id}{datetime} = '2008-10-28 09:08:00';
      $self->{reads}{$id}{temperature} = '62.8C';
      $self->{reads}{$id}{dissolved_oxygen} = 0;
      $self->{reads}{$id}{dissolved_sulfide} = 0;
      $self->{reads}{$id}{irradiance} = 124;
      $self->{reads}{$id}{ph} = 0;
      $self->{reads}{$id}{layer} = 'top 5mm';
      $self->{reads}{$id}{size} = 'unknown';
      $self->{reads}{$id}{extracted} = 'Chris Klatt';
    }
    if (defined $self->{reads}{$id}{source} && $self->{reads}{$id}{source} eq 'mush65c') {
      $self->{reads}{$id}{metagenome} = 'mush65c';
      $self->{reads}{$id}{location} = 'Mushroom Spring';
      $self->{reads}{$id}{datetime} = '2008-10-28 09:00:00';
      $self->{reads}{$id}{temperature} = '63.3C';
      $self->{reads}{$id}{dissolved_oxygen} = 0;
      $self->{reads}{$id}{dissolved_sulfide} = 0;
      $self->{reads}{$id}{irradiance} = 124;
      $self->{reads}{$id}{ph} = 0;
      $self->{reads}{$id}{layer} = 'top 5mm';
      $self->{reads}{$id}{size} = 'unknown';
      $self->{reads}{$id}{extracted} = 'Chris Klatt';
    }
    if (defined $self->{reads}{$id}{source} && $self->{reads}{$id}{source} eq 'mush68c') {
      $self->{reads}{$id}{metagenome} = 'mush68c';
      $self->{reads}{$id}{location} = 'Mushroom Spring';
      $self->{reads}{$id}{datetime} = '2008-10-28 09:31:00';
      $self->{reads}{$id}{temperature} = '64.8C';
      $self->{reads}{$id}{dissolved_oxygen} = 0;
      $self->{reads}{$id}{dissolved_sulfide} = 0;
      $self->{reads}{$id}{irradiance} = 124;
      $self->{reads}{$id}{ph} = 0;
      $self->{reads}{$id}{layer} = 'top 2mm';
      $self->{reads}{$id}{size} = 'unknown';
      $self->{reads}{$id}{extracted} = 'Chris Klatt';
    }
  }
}

=head2 _check_bins

  Title    : _check_bins
  Usage    : private
  Function : Returns the pair type of the given id.
  Returns  : The pair type of the given id.
  Args     : bina: First bin to compair
             binb: Second bin to compair
             contiga: First contig to compair
             contigb: Second contig to compair

=cut

sub _check_bins {
  my $self = shift;
  my %params = @_;
  if ( defined $params{bina} && defined $params{binb} &&
       defined $params{contiga} && defined $params{contigb} && 
       $params{bina} eq $params{binb} && $params{bina} ne 'null' &&
       $params{contiga} eq $params{contigb}
     ) {
    return 'paired';
  }
  elsif ( defined $params{bina} && defined $params{binb} &&
          $params{bina} eq $params{binb} && $params{bina} ne 'null'
        ) {
    return 'paired_na';
  }
  elsif (defined $params{bina} && defined $params{binb}) {
    return 'unpaired';
  }
  else {
    return 'nopair';
  }
}


=head2 _check_paired_type

  Title    : _check_paired_type
  Usage    : private
  Function : Returns the direction type of the clone pairs based on the subject's and query's strand.
  Returns  : 'good', 'outie', 'normal', 'antinormal'
  Args     : forward_query: Strand of the forward query
             forward_subject: Strand of the forward subject
             forward_start:
             forward_end:
             reverse_query: Strand of the reverse query
             reverse_subject: Strand of the reverse subject
             reverse_start:
             reverse_end:
             genome_size:
             size_range:

=cut

sub _check_paired_type {
  my $self = shift;
  my %params = @_;
  my $statistics = new Pigeon::Statistics ();
  my $type;
  my $min = $statistics->minimum ([
    $params{forward_start},
    $params{forward_end},
    $params{reverse_start},
    $params{reverse_end}
  ]);
  my $max = $statistics->maximum ([
    $params{forward_start},
    $params{forward_end},
    $params{reverse_start},
    $params{reverse_end}
  ]);
  my $size = $max - $min;
  my $normal = $size < ($params{genome_size} / 2);
  if (not $normal) {
    $size = $params{genome_size} - $max + $min;
  }
  my $size_type = $self->_check_size (
    size       => $size,
    size_range => $params{size_range}
  );
  my $direction;
  # Check which end comes first, or if they overlap.
  if (($params{forward_start} < $params{reverse_start} && $params{forward_start} < $params{reverse_end}) &&
      ($params{forward_end} < $params{reverse_start} && $params{forward_end} < $params{reverse_end})) {
    if ($normal) {
      $direction = $self->_check_strand (
        forward_query   => $params{forward_query},
        forward_subject => $params{forward_subject},
        reverse_query   => $params{reverse_query},
        reverse_subject => $params{reverse_subject}
      );
    }
    else {
      $direction = $self->_check_strand (
        forward_query   => $params{reverse_query},
        forward_subject => $params{reverse_subject},
        reverse_query   => $params{forward_query},
        reverse_subject => $params{forward_subject}
      );
    }
    $type = '_' . $direction . '_' . $size_type;
  }
  elsif (($params{forward_start} > $params{reverse_start} && $params{forward_start} > $params{reverse_end}) &&
         ($params{forward_end} > $params{reverse_start} && $params{forward_end} > $params{reverse_end})) {
     if ($normal) {
      $direction = $self->_check_strand (
        forward_query   => $params{reverse_query},
        forward_subject => $params{reverse_subject},
        reverse_query   => $params{forward_query},
        reverse_subject => $params{forward_subject}
      );
    }
    else {
      $direction = $self->_check_strand (
        forward_query   => $params{forward_query},
        forward_subject => $params{forward_subject},
        reverse_query   => $params{reverse_query},
        reverse_subject => $params{reverse_subject}
      );
    }
    $type = '_' . $direction . '_' . $size_type;
  }
  else {
    $type = '_overlap';
  }
  return $type;
}

=head2 _check_strand

  Title    : _check_strand
  Usage    : private
  Function : Returns the direction type of the clone pairs based on the subject's and query's strand.
  Returns  : 'good', 'outie', 'normal', 'antinormal'
  Args     : forward_query: Strand of the forward query
             forward_subject: Strand of the forward subject
             reverse_query: Strand of the reverse query
             reverse_subject: Strand of the reverse subject

=cut

sub _check_strand {
  my $self = shift;
  my %params = @_;
  my $direction = '';
  if (defined $params{forward_query} && defined $params{forward_subject} && defined $params{reverse_query} && defined $params{reverse_subject}) {
    # Check for 'good' direction in clone pairs.
    if (($params{forward_query} eq  '1' && $params{forward_subject} eq  '1' && $params{reverse_query} eq  '1' && $params{reverse_subject} eq '-1') ||
        ($params{forward_query} eq  '1' && $params{forward_subject} eq  '1' && $params{reverse_query} eq '-1' && $params{reverse_subject} eq  '1') ||
        ($params{forward_query} eq '-1' && $params{forward_subject} eq '-1' && $params{reverse_query} eq  '1' && $params{reverse_subject} eq '-1') ||
        ($params{forward_query} eq '-1' && $params{forward_subject} eq '-1' && $params{reverse_query} eq '-1' && $params{reverse_subject} eq  '1')) {
      $direction = 'good';
    }
    # Check for 'outie' direction in clone pairs.
    elsif (($params{forward_query} eq  '1' && $params{forward_subject} eq '-1' && $params{reverse_query} eq  '1' && $params{reverse_subject} eq  '1') ||
           ($params{forward_query} eq  '1' && $params{forward_subject} eq '-1' && $params{reverse_query} eq '-1' && $params{reverse_subject} eq '-1') ||
           ($params{forward_query} eq '-1' && $params{forward_subject} eq  '1' && $params{reverse_query} eq  '1' && $params{reverse_subject} eq  '1') ||
           ($params{forward_query} eq '-1' && $params{forward_subject} eq  '1' && $params{reverse_query} eq '-1' && $params{reverse_subject} eq '-1')) {
    $direction = 'outie';
    }
    # Check for 'antinormal' direction in clone pairs.
    elsif (($params{forward_query} eq  '1' && $params{forward_subject} eq '-1' && $params{reverse_query} eq  '1' && $params{reverse_subject} eq '-1') ||
           ($params{forward_query} eq  '1' && $params{forward_subject} eq '-1' && $params{reverse_query} eq '-1' && $params{reverse_subject} eq  '1') ||
           ($params{forward_query} eq '-1' && $params{forward_subject} eq  '1' && $params{reverse_query} eq  '1' && $params{reverse_subject} eq '-1') ||
           ($params{forward_query} eq '-1' && $params{forward_subject} eq  '1' && $params{reverse_query} eq '-1' && $params{reverse_subject} eq  '1')) {
      $direction = 'antinormal';
    }
    # Check for 'normal' direction in clone pairs.
    elsif (($params{forward_query} eq  '1' && $params{forward_subject} eq  '1' && $params{reverse_query} eq  '1' && $params{reverse_subject} eq  '1') ||
           ($params{forward_query} eq  '1' && $params{forward_subject} eq  '1' && $params{reverse_query} eq '-1' && $params{reverse_subject} eq '-1') ||
           ($params{forward_query} eq '-1' && $params{forward_subject} eq '-1' && $params{reverse_query} eq  '1' && $params{reverse_subject} eq  '1') ||
           ($params{forward_query} eq '-1' && $params{forward_subject} eq '-1' && $params{reverse_query} eq '-1' && $params{reverse_subject} eq '-1')) {
      $direction = 'normal';
    }
    return $direction;
  }
  else {
    return '';
  }
}

=head2 _check_size

  Title    : _check_size
  Usage    : private
  Function : Returns the size type of the clone pairs based on the size of the
             hit, the contig's size, and the level of error allowed.
  Returns  : 'short', 'long', 'good'
  Args     : size: Size of the hit
             size_range: Size range of clone

=cut

sub _check_size {
  my $self = shift;
  my %params = @_;
  my ($error, $low, $high);
  if (defined $params{size} && defined $params{size_range}) {
    # Get Low - High range
    ($low, $_) = split(/ /, $params{size_range});
    ($low, $high) = split(/-/, $low);
    $low *= 1000;
    $high *= 1000;
    # Calculate error.
    $error = (($low + $high) / 2) * $self->{synteny_error};
    # Return syntenous flag
    if ($params{size} < ($low - $error)) {
      return 'short';
    }
    elsif ($params{size} > ($high + $error)) {
      return 'long';
    }
    elsif ($params{size} <= ($high + $error) && $params{size} >= ($low - $error)) {
      return 'good';
    }
  }
  else {
    return '';
  }
}

=head2 _screen_conserved

  Title    : _screen_conserved
  Usage    : private
  Function : Fills the hash %conserved with reads hitting conserved genes in the A and B' bins
  Args     : low_cutoff: Percentage to use as lower cutoff
             high_cutoff: Percentage to use as upper cutoff
=cut

sub _screen_conserved {
  my $self = shift;
  my %params = @_;
  my %syna_binblast = ();
  my %synbpr_binblast = ();
  my %homolog_list = ();
  my %recip_homolog_list = ();
  my @syna = ();
  my @synbpr = ();
  my @conserved_list = ();
  my %conserved = ();
  my ($low_cutoff, $high_cutoff);
  if (defined $params{low}) {
    $low_cutoff = $params{low};
  }
  else {
    $low_cutoff = 0;
  }
  if (defined $params{high}) {
    $high_cutoff = $params{high};
  }
  else {
    $high_cutoff = 100;
  }
  # Get list of reads in A and B' bins, read into array 
  foreach my $id (keys %{$self->{reads}}) {
    if ($self->{reads}{$id}{bin} =~ "synechococcus_sp._os-type_a_strain" ) {
      push (@syna, $id);
    }
    elsif ($self->{reads}{$id}{bin} =~ "synechococcus_sp._os-type_b'_strain") {
      push (@synbpr, $id);
    }
  }
  # Read homolog data into hash of arrays, "GYMAORF -> (GYMBORF, %NA_ID)" 
  open (HOMOLOGS, $params{homolog_filename}) or die "Can't open $params{homolog_filename}!\n";
    while (my $line = <HOMOLOGS>) {
      $line =~ s/[\n\r]//g;
      my ($orfA, $orfB, $na_id ) = split("\t", $line);
      my @homolog = ($orfB, $na_id);
      if ($orfA ne '') {
        $homolog_list{$orfA} = [@homolog];
      }
    }
  close (HOMOLOGS);
  # Create reciprocal homolog_list hash
  foreach my $orfA (keys %homolog_list) {
    $recip_homolog_list{$homolog_list{$orfA}[0]} = $orfA;
  }
  # Read in blast output from A bin vs A genome into hash of array, "READ -> (GYMAORF, %NA_ID, %_READ_LENGTH)
  open (SYNABINBLAST, $params{genone_vs_gentwo}) or die "Can't open $params{genone_vs_gentwo}!\n";
    while (my $line = <SYNABINBLAST>) {
      my ($id, $qlength, $orfA, $percent, $alength ) = split("\t", $line);
      ($_, $id) = split(/\|/, $id);
      my $fraqa = $alength / $qlength * 100;
      my @array = ($orfA, $percent, $fraqa);
      $syna_binblast{$id} = [@array];
    }
  close (SYNABINBLAST);
  # Read in blast output from Bpr bin vs Bpr genome into hash of array, "READ -> (GYMBORF, %NA_ID, %_READ_LENGTH)   
  open (SYNBPRBINBLAST, $params{gentwo_vs_genone}) or die "Can't open $params{gentwo_vs_genone}!\n";
    while (my $line = <SYNBPRBINBLAST>) {
      my ($id, $qlength, $orfB, $percent, $alength) = split( "\t", $line);
      ($_, $id) = split(/\|/, $id);
      my $fraqb = $alength / $qlength * 100;
      my @array = ($orfB, $percent, $fraqb);
      $synbpr_binblast{$id} = [@array];
    }
  close (SYNBPRBINBLAST);
  # Create list of conserved ORFs given cutoffs
  foreach my $conserved (keys %homolog_list) {
    if ($homolog_list{$conserved}[1] <= $low_cutoff || $homolog_list{$conserved}[1] >= $high_cutoff) {
      push (@conserved_list, $conserved);
    }
  }
  # For each read in the A and B' bins, check to see if it hits an orf in @conserved_list 
  foreach my $id (keys %syna_binblast) {
    for my $i (0 .. $#conserved_list) {
      if (defined $homolog_list{$syna_binblast{$id}[0]} && $syna_binblast{$id}[0] =~ $conserved_list[$i]) {
        $conserved{$id} = 1;
      }
    }
  }
  foreach my $id (keys %synbpr_binblast ) {
    for my $i (0 .. $#conserved_list) {
      if (defined $recip_homolog_list{$synbpr_binblast{$id}[0]} && $recip_homolog_list{$synbpr_binblast{$id}[0]} =~ $conserved_list[$i]) {
        $conserved{$id} = 1;
      }
    }
  }
  return %conserved
}

=head2 _test

  Title    : _test
  Usage    : private
  Function : Tests
  Returns  : True or False
  Args     : item: Item to test against the list
             list: Array reference to the list

=cut

sub _test {
  my %params = @_;
  if ( contains (%params) || contains (item => 'total', list => $params{list}) ) {
    return 1;
  }
  else {
    return 0;
  }
}



sub _oldnew_readname {
  my @params = @_;
  my %oldnew;
  my $oldnew = $params[1];
  open (OLDNEW, $oldnew) or die "Can't open $oldnew: $!\n";
  foreach my $line (<OLDNEW>) {
    chomp $line;
    $line =~ s/No definition line found\t//g;
    $line =~ s/lcl//g;
    $line =~ s/[>|\|]//g;
    (my $old, my $new, $_, my $newmate, $_) = split(" ", $line, 5);
    $oldnew{$new} = $old;
  }
  close (OLDNEW);
  return %oldnew;
}

1;
__END__

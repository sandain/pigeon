=head1 NAME

  Pigeon::Graphics - Produces graphics from information stored in a Pigeon::Data object.

=head1 SYNOPSIS

  Private usage by Pigeon.

=head1 DESCRIPTION

  This package produces graphics from information stored in a Pigeon::Data object.

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

package Pigeon::Graphics;

use strict;
use warnings;

use Pigeon::Cluster;
use Pigeon::Data;
use Pigeon::Data::PCA;
use Pigeon::Fasta;
use Pigeon::Graphics::GD;
use Pigeon::Graphics::Image;
#use Pigeon::Graphics::OpenGL;
use Pigeon::Tools qw(:all);
use POSIX qw(ceil floor);

=head2 new

  Title    : new
  Usage    : my $data = new Pigeon::Data();
             my $graphics = new Pigeon::Graphics(
               pigeon_data = $data
             );
  Function : Creates a new Pigeon::Graphics object for use in the Pigeon package.
  Returns  : Pigeon::Graphics object
  Args     : pigeon_data: Pigeon::Data object

=cut

sub new {
  my $invocant = shift;
  my %params = @_;
  my $class = ref($invocant) || $invocant;
  my $self = {
    pigeon_data => undef,
    gd          => undef,
    image       => undef,
#    opengl      => undef
  };
  bless $self => $class;
  if (defined $params{pigeon_data}) {
    $self->{pigeon_data} = $params{pigeon_data};
    $self->{gd} = new Pigeon::Graphics::GD ();
    $self->{image} = new Pigeon::Graphics::Image ();
#    $self->{opengl} = new Pigeon::Graphics::OpenGL ();
  }
  else {
    # No parameters supplied, throw error
    print "Error in call to Pigeon::Graphics, no parameters supplied.\n";
    print "Syntax: new Pigeon::Graphics(<Pigeon::Data object>)\n";
  }
  return $self;
}

=head2 color

  Title    : color
  Usage    : my $color = $image->color(0, 255, 0, 1.0);  # Green
  Function : Returns the given RGBA in an Image::Magick readable format.
  Return   : String containing the RGBA value.
  Args     : r: Red value.
             g: Green value.
             b: Blue value.
             a: Alpha value, optional.

=cut

sub color {
  my $self = shift;
  return $self->{image}->color(@_);  
}

=head2 hit_quality_graph

  Title    : hit_quality_graph
  Usage    : $graph->hit_quality_graph(
               bins => ['syna', 'synbpr'],
               file_name => 'hit_quality_graph.gif'
             );
  Function : Creates a Hit Quality Graph for the provided bins, etc.
  Args     : file_name: File name, defaults to 'hit_quality_graph.gif'
             title: Title of this graphic, defaults to 'Hit Quality'
             title_justify: left, center, right, default center
             title_font: File name of font to use
             title_font_size: Size of title font
             normal_font: File name of font to use
             normal_font_size: Size of normal font
             legend : Array reference to the legend, defaults to calculated.
             legend_location: Location to draw the legend: top, bottom, or none
             legend_justify: Justify of the legend: left, center, right
             width: Width of image
             height: Height of image
             ids: Array reference of read ids to use, optional
             bins: Array reference of valid bins to include, defaults to total
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
                 paired_overlap:           Include Paired clone pairs that overlap.
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
                 paired_nonsyntenous:      Include Paired-NonSyntenous type clone pairs.
                 paired:                   Include Paired-Syntenous and Paired-NonSyntenous type clone pairs.
                 total:                    Include all reads.
             colors: Array reference of colors to use for the above categories
             low: Lowest value NtID to plot, default 50
             high: Highest value NtID to plot, default 100
             relative: Boolean, whether or not to use the relative or simple frequency in calculations.
                 0: Simple frequency, dependant on only the category's data.
                 1: Relative frequency, dependant on the total data, default.

=cut

sub hit_quality_graph {
  my $self = shift;
  my %params = check_parameters (
    params   => \@_,
    type     => 'graphics',
    defaults => {
      file_name       => 'hit_quality_graph.gif',
      legend_location => 'bottom',
      legend_justify  => 'center',
      width           => 800,
      height          => 300,
      low             => 50,
      high            => 100,
      relative        => 1
    }
  );
  my %reads = $self->{pigeon_data}->reads(%params);
  my (%data, @data, @legend);
  my $counter = 0;
  my $high_value = 0;
  my $yaxis_step = 10;
  # Init %data
  foreach my $bin (@{$params{bins}}) {
    foreach my $category (@{$params{categories}}) {
      foreach my $metagenome (@{$params{metagenomes}}) {
        $data{$metagenome}{$category}{$bin}{counter} = 0;
        $data{$metagenome}{$category}{$bin}{array} = [];
        if (@{$params{bins}} > 1 || (@{$params{metagenomes}} == 1 && @{$params{categories}} == 1)) {
          $data{$metagenome}{$category}{$bin}{title} .= $self->{pigeon_data}->long_description(bin => $bin) . ' ';
        }
        if (@{$params{metagenomes}} > 1) {
          $data{$metagenome}{$category}{$bin}{title} .= $self->{pigeon_data}->long_description(bin => $metagenome) . ' ';
        }
        if (@{$params{categories}} > 1) {
          $data{$metagenome}{$category}{$bin}{title} .= $self->{pigeon_data}->long_description(bin => $category) . ' ';
        }
      }
    }
  }
  # Count the hits for each bin and category combo.
  foreach my $id (keys %reads) {
    my $identity = round ($reads{$id}{percent_identity} - $params{low});
    next if ($identity < 0);
    $data{$reads{$id}{metagenome}}{$reads{$id}{type}}{$reads{$id}{bin}}{array}[$identity] ++;
    $data{$reads{$id}{metagenome}}{$reads{$id}{type}}{$reads{$id}{bin}}{counter} ++;
    $data{'total'}{$reads{$id}{type}}{$reads{$id}{bin}}{array}[$identity] ++;
    $data{'total'}{$reads{$id}{type}}{$reads{$id}{bin}}{counter} ++;
    $counter ++;
    if (defined $data{$reads{$id}{metagenome}}{'paired_syntenous'} && $reads{$id}{type} eq 'paired_good_good') {
      $data{$reads{$id}{metagenome}}{'paired_syntenous'}{$reads{$id}{bin}}{array}[$identity] ++;
      $data{$reads{$id}{metagenome}}{'paired_syntenous'}{$reads{$id}{bin}}{counter} ++;
      $data{$reads{$id}{metagenome}}{'paired_syntenous'}{'total'}{array}[$identity] ++;
      $data{$reads{$id}{metagenome}}{'paired_syntenous'}{'total'}{counter} ++;
    }
    if (defined $data{'total'}{'paired_syntenous'} && $reads{$id}{type} eq 'paired_good_good') {
      $data{'total'}{'paired_syntenous'}{$reads{$id}{bin}}{array}[$identity] ++;
      $data{'total'}{'paired_syntenous'}{$reads{$id}{bin}}{counter} ++;
      $data{'total'}{'paired_syntenous'}{'total'}{array}[$identity] ++;
      $data{'total'}{'paired_syntenous'}{'total'}{counter} ++;
    }
    if (defined $data{$reads{$id}{metagenome}}{'paired_nonsyntenous'} && (
        $reads{$id}{type} eq 'paired_overlap' ||
        $reads{$id}{type} eq 'paired_good_short' ||
        $reads{$id}{type} eq 'paired_good_long' ||
        $reads{$id}{type} =~ /^paired_outie/ ||
        $reads{$id}{type} =~ /^paired_antinormal/ ||
        $reads{$id}{type} =~ /^paired_normal/
      )) {
      $data{$reads{$id}{metagenome}}{'paired_nonsyntenous'}{$reads{$id}{bin}}{array}[$identity] ++;
      $data{$reads{$id}{metagenome}}{'paired_nonsyntenous'}{$reads{$id}{bin}}{counter} ++;
      $data{$reads{$id}{metagenome}}{'paired_nonsyntenous'}{'total'}{array}[$identity] ++;
      $data{$reads{$id}{metagenome}}{'paired_nonsyntenous'}{'total'}{counter} ++;
    }
    if (defined $data{'total'}{'paired_nonsyntenous'} && (
        $reads{$id}{type} eq 'paired_overlap' ||
        $reads{$id}{type} eq 'paired_good_short' ||
        $reads{$id}{type} eq 'paired_good_long' ||
        $reads{$id}{type} =~ /^paired_outie/ ||
        $reads{$id}{type} =~ /^paired_antinormal/ ||
        $reads{$id}{type} =~ /^paired_normal/
      )) {
      $data{'total'}{'paired_nonsyntenous'}{$reads{$id}{bin}}{array}[$identity] ++;
      $data{'total'}{'paired_nonsyntenous'}{$reads{$id}{bin}}{counter} ++;
      $data{'total'}{'paired_nonsyntenous'}{'total'}{array}[$identity] ++;
      $data{'total'}{'paired_nonsyntenous'}{'total'}{counter} ++;
    }
    if (defined $data{$reads{$id}{metagenome}}{'paired'} && $reads{$id}{type} =~ /^paired/) {
      $data{$reads{$id}{metagenome}}{'paired'}{$reads{$id}{bin}}{array}[$identity] ++;
      $data{$reads{$id}{metagenome}}{'paired'}{$reads{$id}{bin}}{counter} ++;
      $data{$reads{$id}{metagenome}}{'paired'}{'total'}{array}[$identity] ++;
      $data{$reads{$id}{metagenome}}{'paired'}{'total'}{counter} ++;
    }
    if (defined $data{'total'}{'paired'} && $reads{$id}{type} =~ /^paired/) {
      $data{'total'}{'paired'}{$reads{$id}{bin}}{array}[$identity] ++;
      $data{'total'}{'paired'}{$reads{$id}{bin}}{counter} ++;
      $data{'total'}{'paired'}{'total'}{array}[$identity] ++;
      $data{'total'}{'paired'}{'total'}{counter} ++;
    }
    if (defined $data{$reads{$id}{metagenome}}{'total'}) {
      $data{$reads{$id}{metagenome}}{'total'}{$reads{$id}{bin}}{array}[$identity] ++;
      $data{$reads{$id}{metagenome}}{'total'}{$reads{$id}{bin}}{counter} ++;
      $data{$reads{$id}{metagenome}}{'total'}{'total'}{array}[$identity] ++;
      $data{$reads{$id}{metagenome}}{'total'}{'total'}{counter} ++;
    }
    if (defined $data{'total'}{'total'}) {
      $data{'total'}{'total'}{$reads{$id}{bin}}{array}[$identity] ++;
      $data{'total'}{'total'}{$reads{$id}{bin}}{counter} ++;
      $data{'total'}{'total'}{'total'}{array}[$identity] ++;
      $data{'total'}{'total'}{'total'}{counter} ++;
    }
  }
  # Turn each count into a percent of total.
  for (my $i = 0; $i <= $params{high} - $params{low}; $i++) {
    $data[0][$i] = $i + $params{low};
    foreach my $bin (@{$params{bins}}) {
      foreach my $category (@{$params{categories}}) {
        foreach my $metagenome (@{$params{metagenomes}}) {
          if (defined $data{$metagenome}{$category}{$bin}{array}[$i] && $counter > 0) {
            if ($params{relative}) {
              $data{$metagenome}{$category}{$bin}{array}[$i] = 100 * $data{$metagenome}{$category}{$bin}{array}[$i] / $counter;
            }
            else {
              $data{$metagenome}{$category}{$bin}{array}[$i] = 100 * $data{$metagenome}{$category}{$bin}{array}[$i] / $data{$metagenome}{$category}{$bin}{counter};
            }
            if ($data{$metagenome}{$category}{$bin}{array}[$i] > $high_value) {
              $high_value = $data{$metagenome}{$category}{$bin}{array}[$i];
            }
          }
          else {
            $data{$metagenome}{$category}{$bin}{array}[$i] = undef;
          }
        }
      }
    }
  }
  # Format @data and @legend from %data.
  my $i = 0;
  foreach my $bin (@{$params{bins}}) {
    foreach my $category (@{$params{categories}}) {
      foreach my $metagenome (@{$params{metagenomes}}) {
        $data[$i + 1] = $data{$metagenome}{$category}{$bin}{array};
        if (defined $params{legend} && defined $params{legend}->[$i]) {
          $legend[$i] = $params{legend}->[$i] . ' ';
        }
        else {
          $legend[$i] = $data{$metagenome}{$category}{$bin}{title};
        }
        $legend[$i] .= '(' . $data{$metagenome}{$category}{$bin}{counter} . ')';
        $i++;
      }
    }
  }
  # Set Y axis max by rounding highest value up to nearest $yaxis_step
  if ($high_value == 0) {
    $high_value = $yaxis_step;
  }
  $high_value = ceil($high_value / $yaxis_step) * $yaxis_step;
  # If there is a title defined, add the number of reads as a subtitle.
  my $subTitle;
  $subTitle = $counter . ' reads' if (defined $params{title});
  # Create graph of data
  $self->{gd}->drawBarGraph (
    data              => \@data,
    dataColors        => $params{colors},
    legend            => \@legend,
    legendTitle       => undef,
    xAxisTitle        => "% nt Identity",
    yAxisTitle        => 'Frequency (%)',
    xLabelSkip        => 5,
    yLabelSkip        => 1,
    maximumValue      => $high_value,
    width             => $params{width},
    height            => $params{height},
    fileName          => $params{file_name},
    backgroundColor   => 'white',
    title             => $params{title},
    titleAlignment    => $params{title_justify},
    titleFont         => $params{title_font},
    titleFontSize     => $params{title_font_size},
    titleColor        => 'black',
    subTitle          => $subTitle,
    subTitleAlignment => $params{title_justify},
    subTitleFont      => $params{normal_font},
    subTitleFontSize  => $params{normal_font_size},
    subTitleColor     => 'black',
    labelFont         => $params{normal_font},
    labelFontSize     => $params{normal_font_size},
    labelColor        => 'black',
    legendType        => 'classic',
    legendLocation    => $params{legend_location},
    legendAlignment   => $params{legend_justify},
    legendFont        => $params{normal_font},
    legendFontSize    => $params{normal_font_size},
    legendColor       => 'black',
    cumulate          => 0
  );
}

=head2 forced_hit_quality_graph

  Title    : forced_hit_quality_graph
  Usage    : $graph->forced_hit_quality_graph(
               bins => ['syna', 'synbpr'],
               file_name => 'forced_hit_quality_graph.gif'
             );
  Function : Creates a Forced Hit Quality graphic.
  Args     : file_name: File name, defaults to 'forced_hit_quality_graph.gif'
             title: Title of this graphic
             title_justify: left, center, right, default center
             title_font: File name of font to use
             title_font_size: Size of title font
             normal_font: File name of font to use
             normal_font_size: Size of normal font
             width: Width of image
             height: Height of image
             forced_bins: Array reference of valid forced bins to include
             bins: Array reference of valid bins to include, defaults to total
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
                 paired_overlap:           Include Paired clone pairs that overlap.
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
                 paired_nonsyntenous:      Include Paired-NonSyntenous type clone pairs.
                 paired:                   Include Paired-Syntenous and Paired-NonSyntenous type clone pairs.
                 total:                    Include all reads.
             colors: Array reference of colors to use for the above categories
             low: Lowest value NtID to plot, default 50
             high: Highest value NtID to plot, default 100

=cut

sub forced_hit_quality_graph {
  my $self = shift;
  my %params = check_parameters (
    params   => \@_,
    type     => 'graphics',
    defaults => {
      file_name       => 'forced_hit_quality_graph.gif',
      legend_location => 'bottom',
      legend_justify  => 'center',
      width           => 700,
      height          => 300,
      low             => 50,
      high            => 100
    }
  );
  my %reads = $self->{pigeon_data}->reads();
  my %forced = $self->{pigeon_data}->forced(%params);
  my (@data, @legend, @counter);
  my $yaxis_step = 10;
  my $high_value = 0;
  my $counter = 0;
  # Grab data for each forced_bin
  for (my $i = 0; $i < @{$params{forced_bins}}; $i ++) {
    $counter[$i + 1] = 0;
    foreach my $id (keys %{$forced{$params{forced_bins}->[$i]}}) {
      $data[$i + 1][round ($forced{$params{forced_bins}->[$i]}{$id}{percent_identity}) - $params{low}] ++;
      $counter[$i + 1] ++;
      $counter ++;
    }
  }
  # Turn each count into a percent of total
  for (my $i = 0; $i <= $params{high} - $params{low}; $i++) {
    $data[0][$i] = $i + $params{low};
    for (my $j = 0; $j < @{$params{forced_bins}}; $j++) {
      if (defined $data[$j + 1][$i] && $counter[$j + 1] > 0) {
        $data[$j + 1][$i] = 100 * $data[$j + 1][$i] / $counter[$j + 1];
        if ($data[$j + 1][$i] > $high_value) {
          $high_value = $data[$j + 1][$i];
        }
      }
      else {
        $data[$j + 1][$i] = undef;
      }
    }
  }
  # Create legend
  for (my $i = 0; $i < @{$params{forced_bins}}; $i ++) {
    $legend[$i] = $self->{pigeon_data}->long_description(bin => $params{forced_bins}->[$i]);
    $legend[$i] .= ' (' . $counter[$i + 1] . ' reads)';
  }
  # Make $high_value a nice number
  if ($high_value == 0) {
    $high_value = $yaxis_step;
  }
  $high_value = ceil($high_value / $yaxis_step) * $yaxis_step;
  $self->{gd}->drawBarGraph (
    data              => \@data,
    dataColors        => $params{colors},
    legend            => \@legend,
    legendTitle       => '',
    xAxisTitle        => "% nt Identity",
    yAxisTitle        => 'Frequency (%)',
    xLabelSkip        => 5,
    yLabelSkip        => 1,
    maximumValue      => $high_value,
    width             => $params{width},
    height            => $params{height},
    fileName          => $params{file_name},
    backgroundColor   => 'white',
    title             => $params{title},
    titleAlignment    => $params{title_justify},
    titleFont         => $params{title_font},
    titleFontSize     => $params{title_font_size},
    titleColor        => 'black',
    subTitle          => $counter . ' reads',
    subTitleAlignment => $params{title_justify},
    subTitleFont      => $params{normal_font},
    subTitleFontSize  => $params{normal_font_size},
    subTitleColor     => 'black',
    labelFont         => $params{normal_font},
    labelFontSize     => $params{normal_font_size},
    labelColor        => 'black',
    legendType        => 'classic',
    legendLocation    => $params{legend_location},
    legendAlignment   => $params{legend_justify},
    legendFont        => $params{normal_font},
    legendFontSize    => $params{normal_font_size},
    legendColor       => 'black',
    cumulate          => 0
  );
}

=head2 assembly_size_graph

  Title    : assembly_size_graph
  Usage    : $graphics->assembly_size_graph();
  Function : Creates a scatter plot of assembly data.
  Args     : file_name: File name, defaults to 'assembly_size_graph.gif'
             title: Title of this graphic
             title_justify: left, center, right, default center
             title_font: File name of font to use
             title_font_size: Size of title font
             normal_font: File name of font to use
             normal_font_size: Size of normal font
             width: Width of image
             height: Height of image
             bins: Array reference of valid bins to include, defaults to total
             assembly_name: 
             reads: 

=cut

sub assembly_size_graph {
  my $self = shift;
  my %params = check_parameters (
    params   => \@_,
    type     => 'graphics',
    defaults => {
      file_name       => 'assembly_size_graph.gif',
      legend_location => 'bottom',
      legend_justify  => 'center',
      width           => 900,
      height          => 400,
      low             => 50,
      high            => 100
    }
  );
  # Get reads to examine.
  my %reads;
  if (defined $params{reads}) {
    %reads = %{$params{reads}};
  }
  else {
    %reads = $self->{pigeon_data}->reads(%params);
  }
  # Get assembly to examine.
  if (not defined $params{assembly_name}) {
    return;
  }
  my $assembly = $self->{pigeon_data}->assembly (
    assembly_name => $params{assembly_name}
  );
  my (%assembly, %ntid);
  my @data;
  my $x_max = 0;
  my $x_label_skip = 200000;
  my $x_tic_skip = 100000;
  # Count each
  my @ids = $assembly->ids();
  for (my $i = 0; $i < @ids; $i ++) {
    my $size = $assembly->size(id => $ids[$i]);
    my @identity;
    foreach my $bin (@{$params{bins}}) {
      foreach my $id ($assembly->reads(id => $ids[$i])) {
        if (defined $reads{$id} && $reads{$id}{bin} eq $bin) {
          push (@identity, $reads{$id}{percent_identity});
          if ($size > $x_max) {
            $x_max = $size;
          }
        }
      }
    }
    $data[$i] = [[ [$size, mean(\@identity)] ]];
  }
  # Make $high_value a nice number
  $x_max = ceil($x_max / $x_tic_skip) * $x_tic_skip;
  if ($x_max < $x_label_skip) {
    $x_max = $x_label_skip;
  }
  $self->{image}->plot (
    data            => \@data,
    dataColors      => $params{colors},
    xAxisTitle      => 'Scaffold Length',
    xAxisLocation   => 'bottom',
    xAxisLongTics   => 0,
    xMinimumValue   => 0,
    xMaximumValue   => $x_max,
    yAxisTitle      => '% nt Identity',
    yAxisLocation   => 'left',
    yAxisLongTics   => 0,
    yMinimumValue   => 50,
    yMaximumValue   => 100,
    color           => 'black',
    backgroundColor => 'white',
    width           => $params{width},
    height          => $params{height},
    fileName        => $params{file_name},
    titles          => $params{titles},
    titleAlignment  => $params{title_justify},
    titleFont       => $params{title_font},
    titleFontSize   => $params{title_font_size},
    titleFontColor  => 'black',
    normalFont      => $params{normal_font},
    normalFontSize  => $params{normal_font_size},
    normalFontColor => 'black'
  );
}

=head2 cluster_hit_quality_graph

  Title    : cluster_hit_quality_graph
  Usage    : 
  Function : 
  Returns  : 
  Args     : file_name: File name, defaults to 'forced_hit_quality_graph.gif'
             title: Title of this graphic
             title_justify: left, center, right, default center
             title_font: File name of font to use
             title_font_size: Size of title font
             normal_font: File name of font to use
             normal_font_size: Size of normal font
             width: Width of image
             height: Height of image
             bins: Array reference of valid bins to include, defaults to total
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
                 paired_overlap:           Include Paired clone pairs that overlap.
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
                 paired_nonsyntenous:      Include Paired-NonSyntenous type clone pairs.
                 paired:                   Include Paired-Syntenous and Paired-NonSyntenous type clone pairs.
                 total:                    Include all reads.
             colors: Array reference of colors to use for the above categories
             low: Lowest value NtID to plot, default 50
             high: Highest value NtID to plot, default 100
             cluster: 
             pca_name: 
             oligo_name:
             assembly_name: 
             reads: 
             run: 

=cut

sub cluster_hit_quality_graph {
  my $self = shift;
  my %params = check_parameters (
    params   => \@_,
    type     => 'graphics',
    defaults => {
      file_name       => 'cluster_hit_quality_graph.gif',
      legend_location => 'bottom',
      legend_justify  => 'center',
      width           => 1500,
      height          => 500,
      low             => 50,
      high            => 100,
      run             => 0
    }
  );
  my %reads;
  if (defined $params{reads}) {
    %reads = %{$params{reads}};
  }
  else {
    %reads = $self->{pigeon_data}->reads(%params);
  }
  my (@data, @legend, @counter);
  my $yaxis_step = 10;
  my $high_value = 0;
  my $counter = 0;
  # Require cluster and data params, or return -1.
  if (not defined $params{cluster}    ||
      not defined $params{pca_name}   ||
      not defined $params{oligo_name} ||
      not defined $params{assembly_name}) {
    return -1;
  }
  # Prefeably load oligo clusters if they exist, otherwise PCA.
  my @clusters;
  if (defined $params{oligo_name}) {
    @clusters = $self->{pigeon_data}->clusters (
      k        => $params{k},
      oligo_name => $params{oligo_name}
    );
  }
  elsif (defined $params{pca_name}) {
    @clusters = $self->{pigeon_data}->clusters (
      k        => $params{k},
      pca_name => $params{pca_name}
    );
  }
  my $assembly = $self->{pigeon_data}->assembly (
    assembly_name => $params{assembly_name}
  );
  # Grab the correct cluster run
  my $cluster = $clusters[$params{run}];
  for (my $i = 0; $i < @{$params{bins}}; $i ++) {
    $counter[$i + 1] = 0;
    foreach my $key ($cluster->ids()) {
      if ($cluster->cluster(id => $key) eq $params{cluster}) {
        foreach my $id ($assembly->reads(id => $key)) {
          if ( defined $reads{$id} && $reads{$id}{percent_identity} >= $params{low} &&
               ($reads{$id}{bin} eq $params{bins}->[$i] || $params{bins}->[$i] eq 'total')
             ) {
            $data[$i + 1][round ($reads{$id}{percent_identity} - $params{low})] ++;
            $counter[$i + 1] ++;
            $counter ++;
          }
        }
      }
    }
  }
  # Turn each count into a percent of total
  for (my $i = 0; $i <= $params{high} - $params{low}; $i++) {
    $data[0][$i] = $i + $params{low};
    for (my $j = 0; $j < @{$params{bins}}; $j++) {
      if (defined $data[$j + 1][$i] && $counter > 0) {
        $data[$j + 1][$i] = 100 * $data[$j + 1][$i] / $counter;
        if ($data[$j + 1][$i] > $high_value) {
          $high_value = $data[$j + 1][$i];
        }
      }
      else {
        $data[$j + 1][$i] = undef;
      }
    }
  }
  # Create legend
  for (my $i = 0; $i < @{$params{bins}}; $i ++) {
    $legend[$i] = $self->{pigeon_data}->long_description(bin => $params{bins}->[$i]);
    $legend[$i] .= ' (' . $counter[$i + 1] . ' reads)';
  }
  # Make $high_value a nice number
  if ($high_value == 0) {
    $high_value = $yaxis_step;
  }
  $high_value = ceil($high_value / $yaxis_step) * $yaxis_step;
  $self->{gd}->drawBarGraph (
    data              => \@data,
    dataColors        => $params{colors},
    legend            => \@legend,
    legendTitle       => '',
    xAxisTitle        => "% nt Identity",
    yAxisTitle        => 'Frequency (%)',
    xLabelSkip        => 5,
    yLabelSkip        => 1,
    maximumValue      => $high_value,
    width             => $params{width},
    height            => $params{height},
    fileName          => $params{file_name},
    backgroundColor   => 'white',
    title             => $params{title},
    titleAlignment    => $params{title_justify},
    titleFont         => $params{title_font},
    titleFontSize     => $params{title_font_size},
    titleColor        => 'black',
    subTitle          => $counter . ' reads',
    subTitleAlignment => $params{title_justify},
    subTitleFont      => $params{normal_font},
    subTitleFontSize  => $params{normal_font_size},
    subTitleColor     => 'black',
    labelFont         => $params{normal_font},
    labelFontSize     => $params{normal_font_size},
    labelColor        => 'black',
    legendType        => 'classic',
    legendLocation    => $params{legend_location},
    legendAlignment   => $params{legend_justify},
    legendFont        => $params{normal_font},
    legendFontSize    => $params{normal_font_size},
    legendColor       => 'black',
    cumulate          => 0
  );
}

=head2 delta_ntid_graph

  Title    : delta_ntid_graph
  Usage    : $graph->delta_ntid_graph(
               bin => 'syna',
               file_name => 'delta_ntid_graph.gif'
             );
  Function : Creates a Delta NtID Graph for the provided bins, etc.
  Args     : file_name: File name, defaults to 'delta_ntid_graph.gif'
             title: Title of this graphic
             title_justify: left, center, right, default center
             title_font: File name of font to use
             title_font_size: Size of title font
             normal_font: File name of font to use
             normal_font_size: Size of normal font
             bins: Array reference of valid bins to include, defaults to total
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
                 paired_overlap:           Include Paired clone pairs that overlap.
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
                 paired_nonsyntenous:      Include Paired-NonSyntenous type clone pairs.
                 paired:                   Include Paired-Syntenous and Paired-NonSyntenous type clone pairs.
                 total:                    Include all reads.
             colors: Array reference of colors to use for the above categories
             low: Lowest value NtID to plot, default 0
             high: Highest value NtID to plot, default 50

=cut

sub delta_ntid_graph {
  my $self = shift;
  my %params = check_parameters (
    params   => \@_,
    type     => 'graphics',
    defaults => {
      file_name       => 'delta_ntid_graph.gif',
      legend_location => 'bottom',
      legend_justify  => 'center',
      width           => 700,
      height          => 300,
      low             => 0,
      high            => 50
    }
  );
  my %reads = $self->{pigeon_data}->reads(%params);
  my (%data, @data, @legend);
  my $yaxis_step = 10;
  my $counter = 0;
  my $high_value = 0;
  # Organize categories into a hash.
  for (my $i = 0; $i < @{$params{categories}}; $i ++) {
    $data{${$params{categories}}[$i]} = ();
    $data{${$params{categories}}[$i]}{counter} = 0;
    $data{${$params{categories}}[$i]}{array} = [];
    $data{${$params{categories}}[$i]}{title} = $self->{pigeon_data}->long_description(bin => ${$params{categories}}[$i]) . ' Reads';
  }

#  # Count number of reads at each Delta nt Identity for the given bin, metagenome, and other inputs.
#  if (defined $data{'paired_good_good'} || defined $data{'paired_good_short'} || defined $data{'paired_good_long'} ||
#      defined $data{'paired_outie_good'} || defined $data{'paired_outie_short'} || defined $data{'paired_outie_long'} ||
#      defined $data{'paired_normal_good'} || defined $data{'paired_normal_short'} || defined $data{'paired_normal_long'} ||
#      defined $data{'paired_antinormal_good'} || defined $data{'paired_antinomal_short'} || defined $data{'paired_antinormal_long'} ||
#      defined $data{'paired_syntenous'} || defined $data{'paired_nonsyntenous'} || defined $data{'paired'}) {
#    foreach my $id (keys %paired) {
#      if (($reads{$id}{bin} eq $params{bin} || $params{bin} eq 'total') && 
#          ($reads{$id}{metagenome} =~ /$params{metagenome}/ || $params{metagenome} eq 'total') &&
#          ($reads{$id}{size} =~ /$params{size}/ || $params{size} eq 'total') &&
#          ($reads{$id}{extracted} =~ /$params{extracted}/ || $params{extracted} eq 'total') &&
#          ($reads{$id}{layer} =~ /$params{layer}/ || $params{layer} eq 'total')
#         ) {
#        # Deal with Paired-Syntenous type clone pairs.
#        if (defined $data{'paired_syntenous'} && $paired{$id}{type} eq 'paired_good_good') {
#          if ((abs ($reads{$id}{percent_identity} - $paired{$id}{reverse}{percent_identity}) >= $params{low}) &&
#              (abs ($reads{$id}{percent_identity} - $paired{$id}{reverse}{percent_identity}) <= $params{high})) {
#            $data{'paired_syntenous'}{array}[$params{high} - round (abs ($reads{$id}{percent_identity} - $paired{$id}{reverse}{percent_identity}))] += 2;
#          }
#          $data{'paired_syntenous'}{counter} += 2;
#        }
#        # Deal with Paired-NonSyntenous type clone pairs.
#        elsif (defined $data{'paired_nonsyntenous'} && ($paired{$id}{type} eq 'paired_good_short' || $paired{$id}{type} eq 'paired_good_long' ||
#            $paired{$id}{type} eq 'paired_normal_short' || $paired{$id}{type} eq 'paired_normal_long' || $paired{$id}{type} eq 'paired_normal_good' || 
#            $paired{$id}{type} eq 'paired_antinormal_short' || $paired{$id}{type} eq 'paired_antinormal_long' || $paired{$id}{type} eq 'paired_antinormal_good' || 
#            $paired{$id}{type} eq 'paired_outie_short' || $paired{$id}{type} eq 'paired_outie_long' || $paired{$id}{type} eq 'paired_outie_good')) {
#          if ((abs ($reads{$id}{percent_identity} - $paired{$id}{reverse}{percent_identity}) >= $params{low}) &&
#              (abs ($reads{$id}{percent_identity} - $paired{$id}{reverse}{percent_identity}) <= $params{high})) {
#            $data{'paired_nonsyntenous'}{array}[$params{high} - round (abs ($reads{$id}{percent_identity} - $paired{$id}{reverse}{percent_identity}))] += 2;
#          }
#          $data{'paired_nonsyntenous'}{counter} += 2;
#        }
#        # Deal with Paired type clone pairs.
#        elsif (defined $data{'paired'} &&
#              ($paired{$id}{type} eq 'paired_normal_short' || $paired{$id}{type} eq 'paired_normal_long' || $paired{$id}{type} eq 'paired_normal_good' || 
#               $paired{$id}{type} eq 'paired_antinormal_short' || $paired{$id}{type} eq 'paired_antinormal_long' || $paired{$id}{type} eq 'paired_antinormal_good' || 
#               $paired{$id}{type} eq 'paired_outie_short' || $paired{$id}{type} eq 'paired_outie_long' || $paired{$id}{type} eq 'paired_outie_good' || 
#               $paired{$id}{type} eq 'paired_good_short' || $paired{$id}{type} eq 'paired_good_long' || $paired{$id}{type} eq 'paired_good_good')) {
#          if ((abs ($reads{$id}{percent_identity} - $paired{$id}{reverse}{percent_identity}) >= $params{low}) &&
#              (abs ($reads{$id}{percent_identity} - $paired{$id}{reverse}{percent_identity}) <= $params{high})) {
#            $data{'paired'}{array}[$params{high} - round (abs ($reads{$id}{percent_identity} - $paired{$id}{reverse}{percent_identity}))] += 2;
#          }
#          $data{'paired'}{counter} += 2;
#        }
#        # Deal with all other type clone pairs.
#        elsif (defined $data{$paired{$id}{type}}) {
#          if ((abs ($reads{$id}{percent_identity} - $paired{$id}{reverse}{percent_identity}) >= $params{low}) &&
#              (abs ($reads{$id}{percent_identity} - $paired{$id}{reverse}{percent_identity}) <= $params{high})) {
#            $data{$paired{$id}{type}}{array}[$params{high} - round (abs ($reads{$id}{percent_identity} - $paired{$id}{reverse}{percent_identity}))] += 2;
#          }
#          $data{$paired{$id}{type}}{counter} += 2;
#        }
#      }
#    }
#  }

  # Get total $counter.
  for (my $i=0; $i < @{$params{categories}}; $i++) {
    $counter += $data{${$params{categories}}[$i]}{counter};
  }
  # Turn each count into a percent of total.
  for (my $i = 0; $i <= $params{high} - $params{low}; $i++) {
    $data[0][$i] = $i + $params{low};
    foreach my $category (@{$params{categories}}) {
      if (defined $data{$category}{array}[$i] && $counter > 0) {
        $data{$category}{array}[$i] = 100 * $data{$category}{array}[$i] / $counter;
        if ($data{$category}{array}[$i] > $high_value) {
          $high_value = $data{$category}{array}[$i];
        }
      }
      else {
        $data{$category}{array}[$i] = undef;
      }
    }
  }
  # Format @data and @legend.
  for (my $i = 0; $i < @{$params{categories}}; $i ++) {
    $data[$i + 1] = $data{${$params{categories}}[$i]}{array};
    $legend[$i] = $data{${$params{categories}}[$i]}{title} . " (" . $data{${$params{categories}}[$i]}{counter} . ")";
  }
  # Set Y axis max by rounding highest value up to nearest $yaxis_step
  if ($high_value == 0) {
    $high_value = $yaxis_step;
  }
  $high_value = ceil($high_value / $yaxis_step) * $yaxis_step;
  # Create graph of data
  $self->{gd}->drawBarGraph (
    data              => \@data,
    dataColors        => $params{colors},
    legend            => \@legend,
    legendTitle       => '',
    xAxisTitle        => "Delta % nt Identity",
    yAxisTitle        => 'Frequency (%)',
    xLabelSkip        => 5,
    yLabelSkip        => 1,
    maximumValue      => $high_value,
    width             => $params{width},
    height            => $params{height},
    fileName          => $params{file_name},
    backgroundColor   => 'white',
    title             => $params{title},
    titleAlignment    => $params{title_justify},
    titleFont         => $params{title_font},
    titleFontSize     => $params{title_font_size},
    titleColor        => 'black',
    subTitle          => $counter . ' reads',
    subTitleAlignment => $params{title_justify},
    subTitleFont      => $params{normal_font},
    subTitleFontSize  => $params{normal_font_size},
    subTitleColor     => 'black',
    labelFont         => $params{normal_font},
    labelFontSize     => $params{normal_font_size},
    labelColor        => 'black',
    legendType        => 'classic',
    legendLocation    => $params{legend_location},
    legendAlignment   => $params{legend_justify},
    legendFont        => $params{normal_font},
    legendFontSize    => $params{normal_font_size},
    legendColor       => 'black',
    cumulate          => 0
  );
}

=head2 average_divergence_graph

  Title    : average_divergence_graph
  Usage    : $graph->average_divergence_graph(
               bin => 'syna',
               file_name => 'average_divergence_graph.gif'
             );
  Function : Creates an Average Divergence Graph for the provided bins, etc.
  Args     : file_name: File name, defaults to 'average_divergence_graph.gif'
             title: Title of this graphic
             title_justify: left, center, right, default center
             title_font: File name of font to use
             title_font_size: Size of title font
             normal_font: File name of font to use
             normal_font_size: Size of normal font
             bins: Array reference of valid bins to include, defaults to total
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
                 paired_overlap:           Include Paired clone pairs that overlap.
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
                 paired_nonsyntenous:      Include Paired-NonSyntenous type clone pairs.
                 paired:                   Include Paired-Syntenous and Paired-NonSyntenous type clone pairs.
                 total:                    Include all reads.
             colors: Array reference of colors to use for the above categories
             low: Lowest value NtID to plot, default 0
             high: Highest value NtID to plot, default 50

=cut

sub average_divergence_graph {
  my $self = shift;
  my %params = check_parameters (
    params   => \@_,
    type     => 'graphics',
    defaults => {
      file_name       => 'average_divergence_graph.gif',
      legend_location => 'bottom',
      legend_justify  => 'center',
      width           => 700,
      height          => 300,
      low             => 0,
      high            => 50
    }
  );
  my (%data, @data, @legend);
  my %reads = $self->{pigeon_data}->reads(%params);
  my $yaxis_step = 10;
  my $counter = 0;
  my $high_value = 0;
  # Organize categories into a hash.
  for (my $i = 0; $i < @{$params{categories}}; $i ++) {
    $data{${$params{categories}}[$i]} = ();
    $data{${$params{categories}}[$i]}{counter} = 0;
    $data{${$params{categories}}[$i]}{array} = [];
    $data{${$params{categories}}[$i]}{title} = $self->{pigeon_data}->long_description(bin => ${$params{categories}}[$i]) . ' Reads';
    $data{${$params{categories}}[$i]}{color} = ${$params{colors}}[$i];
  }
  # Count the number of reads at each percent divergence
  foreach my $id (keys %reads) {

  }

#  # Count the number of reads at each percent divergence for the given bin, metagenome, and other inputs.
#  if (defined $data{'paired_good_good'} || defined $data{'paired_good_short'} || defined $data{'paired_good_long'} ||
#      defined $data{'paired_outie_good'} || defined $data{'paired_outie_short'} || defined $data{'paired_outie_long'} ||
#      defined $data{'paired_normal_good'} || defined $data{'paired_normal_short'} || defined $data{'paired_normal_long'} ||
#      defined $data{'paired_antinormal_good'} || defined $data{'paired_antinomal_short'} || defined $data{'paired_antinormal_long'} ||
#      defined $data{'paired_syntenous'} || defined $data{'paired_nonsyntenous'} || defined $data{'paired'}) {
#    foreach my $id (keys %paired) {
#      if (($reads{$id}{bin} eq $params{bin} || $params{bin} eq 'total') && 
#          ($reads{$id}{metagenome} =~ /$params{metagenome}/ || $params{metagenome} eq 'total') &&
#          ($reads{$id}{size} =~ /$params{size}/ || $params{size} eq 'total') &&
#          ($reads{$id}{extracted} =~ /$params{extracted}/ || $params{extracted} eq 'total') &&
#          ($reads{$id}{layer} =~ /$params{layer}/ || $params{layer} eq 'total')
#         ) {
#        # Deal with Paired-Syntenous type clone pairs.
#        if (defined $data{'paired_syntenous'} && $paired{$id}{type} eq 'paired_good_good') {
#          if ((100 - (($reads{$id}{percent_identity} + $paired{$id}{reverse}{percent_identity}) / 2) >= $params{low}) &&
#              (100 - (($reads{$id}{percent_identity} + $paired{$id}{reverse}{percent_identity}) / 2) <= $params{high})) {
#            $data{'paired_syntenous'}{array}[$params{high} - round (100 - ($reads{$id}{percent_identity} + $paired{$id}{reverse}{percent_identity}) / 2)] += 2;
#          }
#          $data{'paired_syntenous'}{counter} += 2;
#        }
#        # Deal with Paired-NonSyntenous type clone pairs.
#        elsif (defined $data{'paired_nonsyntenous'} && ($paired{$id}{type} eq 'paired_good_short' || $paired{$id}{type} eq 'paired_good_long' ||
#            $paired{$id}{type} eq 'paired_normal_short' || $paired{$id}{type} eq 'paired_normal_long' || $paired{$id}{type} eq 'paired_normal_good' || 
#            $paired{$id}{type} eq 'paired_antinormal_short' || $paired{$id}{type} eq 'paired_antinormal_long' || $paired{$id}{type} eq 'paired_antinormal_good' || 
#            $paired{$id}{type} eq 'paired_outie_short' || $paired{$id}{type} eq 'paired_outie_long' || $paired{$id}{type} eq 'paired_outie_good')) {
#          if ((100 - (($reads{$id}{percent_identity} + $paired{$id}{reverse}{percent_identity}) / 2) >= $params{low}) &&
#              (100 - (($reads{$id}{percent_identity} + $paired{$id}{reverse}{percent_identity}) / 2) <= $params{high})) {
#            $data{'paired_nonsyntenous'}{array}[$params{high} - round (100 - ($reads{$id}{percent_identity} + $paired{$id}{reverse}{percent_identity}) / 2)] += 2;
#          }
#          $data{'paired_nonsyntenous'}{counter} += 2;
#        }
#        # Deal with Paired type clone pairs.
#        elsif (defined $data{'paired'} &&
#              ($paired{$id}{type} eq 'paired_normal_short' || $paired{$id}{type} eq 'paired_normal_long' || $paired{$id}{type} eq 'paired_normal_good' || 
#               $paired{$id}{type} eq 'paired_antinormal_short' || $paired{$id}{type} eq 'paired_antinormal_long' || $paired{$id}{type} eq 'paired_antinormal_good' || 
#               $paired{$id}{type} eq 'paired_outie_short' || $paired{$id}{type} eq 'paired_outie_long' || $paired{$id}{type} eq 'paired_outie_good' || 
#               $paired{$id}{type} eq 'paired_good_short' || $paired{$id}{type} eq 'paired_good_long' || $paired{$id}{type} eq 'paired_good_good')) {
#          if ((100 - (($reads{$id}{percent_identity} + $paired{$id}{reverse}{percent_identity}) / 2) >= $params{low}) &&
#              (100 - (($reads{$id}{percent_identity} + $paired{$id}{reverse}{percent_identity}) / 2) <= $params{high})) {
#            $data{'paired'}{array}[$params{high} - round (100 - ($reads{$id}{percent_identity} + $paired{$id}{reverse}{percent_identity}) / 2)] += 2;
#          }
#          $data{'paired'}{counter} += 2;
#        }
#        # Deal with all other type clone pairs.
#        elsif (defined $data{$paired{$id}{type}}) {
#          if ((100 - (($reads{$id}{percent_identity} + $paired{$id}{reverse}{percent_identity}) / 2) >= $params{low}) &&
#              (100 - (($reads{$id}{percent_identity} + $paired{$id}{reverse}{percent_identity}) / 2) <= $params{high})) {
#            $data{$paired{$id}{type}}{array}[$params{high} - round (100 - ($reads{$id}{percent_identity} + $paired{$id}{reverse}{percent_identity}) / 2)] += 2;
#          }
#          $data{$paired{$id}{type}}{counter} += 2;
#        }
#      }
#    } 
#  }

  # Get total $counter.
  for (my $i = 0; $i < @{$params{categories}}; $i++) {
    $counter += $data{${$params{categories}}[$i]}{counter};
  }
  # Turn each count into a percent of total.
  for (my $i = 0; $i <= $params{high} - $params{low}; $i++) {
    $data[0][$i] = $i + $params{low};
    foreach my $cat (@{$params{categories}}) {
      if (defined $data{$cat}{array}[$i] && $counter > 0) {
        $data{$cat}{array}[$i] = 100 * $data{$cat}{array}[$i] / $counter;
        if ($data{$cat}{array}[$i] > $high_value) {
          $high_value = $data{$cat}{array}[$i];
        }
      }
      else {
        $data{$cat}{array}[$i] = undef;
      }
    }
  }
  # Format @data and @legend.
  for (my $i = 0; $i < @{$params{categories}}; $i ++) {
    $data[$i + 1] = $data{${$params{categories}}[$i]}{array};
    $legend[$i] = $data{${$params{categories}}[$i]}{title} . " (" . $data{${$params{categories}}[$i]}{counter} . ")";
  }
  # Set Y axis max by rounding highest value up to nearest $yaxis_step
  if ($high_value == 0) {
    $high_value = $yaxis_step;
  }
  $high_value = ceil($high_value / $yaxis_step) * $yaxis_step;
  # Create graph of data
  $self->{gd}->drawBarGraph (
    data              => \@data,
    dataColors        => $params{colors},
    legend            => \@legend,
    legendTitle       => '',
    xAxisTitle        => "% nt Identity Divergence",
    yAxisTitle        => 'Frequency (%)',
    xLabelSkip        => 5,
    yLabelSkip        => 1,
    maximumValue      => $high_value,
    width             => $params{width},
    height            => $params{height},
    fileName          => $params{file_name},
    backgroundColor   => 'white',
    title             => $params{title},
    titleAlignment    => $params{title_justify},
    titleFont         => $params{title_font},
    titleFontSize     => $params{title_font_size},
    titleColor        => 'black',
    subTitle          => $counter . ' reads',
    subTitleAlignment => $params{title_justify},
    subTitleFont      => $params{normal_font},
    subTitleFontSize  => $params{normal_font_size},
    subTitleColor     => 'black',
    labelFont         => $params{normal_font},
    labelFontSize     => $params{normal_font_size},
    labelColor        => 'black',
    legendType        => 'classic',
    legendLocation    => $params{legend_location},
    legendAlignment   => $params{legend_justify},
    legendFont        => $params{normal_font},
    legendFontSize    => $params{normal_font_size},
    legendColor       => 'black',
    cumulate          => 0
  );
}

=head2 synteny_vs_size_graph

  Title    : synteny_vs_size_graph
  Usage    : $graph->synteny_vs_size_graph(
               bin => 'syna',
               file_name => 'synteny_vs_size_graph.gif'
             );
  Function : Creates a Synteny vs Size Graph for the provided bins, etc.
  Args     : file_name: File name, defaults to 'synteny_vs_size_graph.gif'
             title: Title of this graphic, defaults to 'Synteny vs Size Graph'
             title_justify: left, center, right, default center
             title_font: File name of font to use
             title_font_size: Size of title font
             normal_font: File name of font to use
             normal_font_size: Size of normal font
             bins: Array reference of valid bins to include, defaults to total
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
                 paired_overlap:           Include Paired clone pairs that overlap.
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
                 paired_nonsyntenous:      Include Paired-NonSyntenous type clone pairs.
                 paired:                   Include Paired-Syntenous and Paired-NonSyntenous type clone pairs.
                 total:                    Include all reads.
             colors: Array reference of colors to use for the above categories
             low: Lowest value NtID to plot, default 50
             high: Highest value NtID to plot, default 100
             show_values: 0 hides values, 1 displays values, default 0
             cutoff: Lowest value to display

=cut

sub synteny_vs_size_graph {
  my $self = shift;
  my %params = check_parameters (
    params   => \@_,
    type     => 'graphics',
    defaults => {
      file_name       => 'synteny_vs_size_graph.gif',
      legend_location => 'bottom',
      legend_justify  => 'center',
      width           => 700,
      height          => 300,
      show_values     => 0,
    }
  );
  my %reads = $self->{pigeon_data}->reads(%params);
  my (@data, @legend);
  my @syntenous_counter;
  my @nonsyntenous_counter;
  my $size_index = 0;
  my $title_height = 20;
  for (my $i = 0; $i < @{$params{sizes}}; $i ++) {
    $syntenous_counter[$i] = 0;
    $nonsyntenous_counter[$i] = 0;
  }
  # Count syntenous and non-syntenous pairs.
  foreach my $id (keys %reads) {
    $size_index = 0;
    foreach my $size (@{$params{sizes}}) {
      $data[0][$size_index] = $size;  
      if ( $reads{$id}{type} =~ /^paired_\w+_good/ &&
           ($reads{$id}{size} eq $size || $size eq 'total')
         ) {
        $syntenous_counter[$size_index] ++;
      }
      elsif ( $reads{$id}{type} =~ /^paired/ && $reads{$id}{type} ne 'paired_na' &&
              ($reads{$id}{size} eq $size || $size eq 'total')
            ) {
        $nonsyntenous_counter[$size_index] ++;
      }
      $size_index ++;
    }
  }
  # Convert counts into percentage.
  for (my $i = 0; $i < $size_index; $i++) {
    # Only display values greater than 0.
    if ($syntenous_counter[$i] > 0) {
      $data[1][$i] = $syntenous_counter[$i] / ($syntenous_counter[$i] + $nonsyntenous_counter[$i]) * 100;
    }
    else {
      $data[1][$i] = undef;
      $syntenous_counter[$i] = undef;
    }
  }
  # Create Graphic.
  $self->{gd}->drawLineGraph (
    data              => \@data,
    dataColors        => $params{colors},
    legend            => \@legend,
    legendTitle       => '',
    xAxisTitle        => 'Clone Size',
    yAxisTitle        => 'Frequency (%)',
    xLabelSkip        => 1,
    yLabelSkip        => 1,
    maximumValue      => 100,
    width             => $params{width},
    height            => $params{height},
    fileName          => $params{file_name},
    backgroundColor   => 'white',
    title             => $params{title},
    titleAlignment    => $params{title_justify},
    titleFont         => $params{title_font},
    titleFontSize     => $params{title_font_size},
    titleColor        => 'black',
    subTitle          => '',
    subTitleAlignment => $params{title_justify},
    subTitleFont      => $params{normal_font},
    subTitleFontSize  => $params{normal_font_size},
    subTitleColor     => 'black',
    labelFont         => $params{normal_font},
    labelFontSize     => $params{normal_font_size},
    labelColor        => 'black',
    legendType        => 'classic',
    legendLocation    => $params{legend_location},
    legendAlignment   => $params{legend_justify},
    legendFont        => $params{normal_font},
    legendFontSize    => $params{normal_font_size},
    legendColor       => 'black',
    cumulate          => 0
  );
}

=head2 genome_comparison_graph

  Title    : genome_comparison_graph
  Usage    : $graph->genome_comparison_graph(
               bin => 'syna',
               file_name => 'genome_comparison_graph.gif'
             );
  Function : Creates a Genome Comparison Graph for the provided bins, etc.
  Args     : file_name: File name, defaults to 'genome_comparison_graph.gif'
             title: Title of this graphic, defaults to '
             title_justify: left, center, right, default center
             title_font: File name of font to use
             title_font_size: Size of title font
             normal_font: File name of font to use
             normal_font_size: Size of normal font
             genomes: 
             colors: Array reference of colors to use for the above categories
             low: Lowest value NtID to plot, default 50
             high: Highest value NtID to plot, default 100

=cut

sub genome_comparison_graph {
  my $self = shift;
  my %params = check_parameters (
    params   => \@_,
    type     => 'graphics',
    defaults => {
      file_name       => "genome_comparison_graph.gif",
      legend_location => 'bottom',
      legend_justify  => 'center',
      width           => 800,
      height          => 300,
      low             => 50,
      high            => 100
    }
  );
  my $i = 0;
  my @data;
  my @counter;
  my @legend;
  my $high_value = 0;
  my $yaxis_step = 10;
  my $bin;
  # Create Labels for X axis.
  for (my $j = 0; $j <= $params{high} - $params{low}; $j++) {
    $data[0][$j] = $j + $params{low};
  }
  foreach my $genome (@{$params{genomes}}) {
    $legend[$i] = $self->{pigeon_data}->long_description(bin => $self->{pigeon_data}->parse_bin(bin => $genome->[1]));
    $i ++;
    $counter[$i] = 0;
    # Load metablast info.
    open (GENOME, @$genome[0]) or die "Can't open file @$genome[0]: $!\n";
    while (my $line = <GENOME>) {
      chop $line;
      ($_, $_, $_, $_, $_, $bin, $_, $_, $_, $_, my $percent_id, $_) = split (/\t/, $line);
      $bin = $self->{pigeon_data}->parse_bin(bin => $bin);
      if ($bin ne 'null') {
        my $j = round ($percent_id - $params{low});
        $data[$i][$j] ++;
        $counter[$i] ++;

      }
    }
    close(GENOME);
  }
  # Convert counts into percentages, and set $high_value
  for (my $i=1; $i <= @{$params{genomes}}; $i++) {
    for (my $j=0; $j <= $params{high} - $params{low}; $j++) {
      if ($data[$i][$j] && $counter[$i] > 0) {
        $data[$i][$j] = $data[$i][$j] / $counter[$i] * 100;
        if ($data[$i][$j] > $high_value) {
          $high_value = $data[$i][$j];
        }
      }
    }
  }
  # Set Y axis max by rounding highest value up to nearest $yaxis_step
  if ($high_value == 0) {
    $high_value = $yaxis_step;
  }
  $high_value = ceil($high_value / $yaxis_step) * $yaxis_step;
  $self->{gd}->drawBarGraph (
    data              => \@data,
    dataColors        => $params{colors},
    legend            => \@legend,
    legendTitle       => '',
    xAxisTitle        => "% nt Identity",
    yAxisTitle        => 'Frequency (%)',
    xLabelSkip        => 5,
    yLabelSkip        => 1,
    maximumValue      => $high_value,
    width             => $params{width},
    height            => $params{height},
    fileName          => $params{file_name},
    backgroundColor   => 'white',
    title             => $params{title},
    titleAlignment    => $params{title_justify},
    titleFont         => $params{title_font},
    titleFontSize     => $params{title_font_size},
    titleColor        => 'black',
    subTitle          => '',
    subTitleAlignment => $params{title_justify},
    subTitleFont      => $params{normal_font},
    subTitleFontSize  => $params{normal_font_size},
    subTitleColor     => 'black',
    labelFont         => $params{normal_font},
    labelFontSize     => $params{normal_font_size},
    labelColor        => 'black',
    legendType        => 'classic',
    legendLocation    => $params{legend_location},
    legendAlignment   => $params{legend_justify},
    legendFont        => $params{normal_font},
    legendFontSize    => $params{normal_font_size},
    legendColor       => 'black',
    cumulate          => 0
  );
}

=head2 synteny_size_deviation_graph

  Title    : synteny_size_deviation_graph
  Usage    : $graph->synteny_size_deviation_graph(
               bins => ['syna'],
               file_name => 'synteny_size_deviation_graph.gif'
             );
  Function : Creates a Synteny Error Graph for the provided bins, etc.
  Args     : file_name: File name, defaults to 'synteny_size_deviation_graph.gif'
             title: Title of this graphic
             title_justify: left, center, right, default center
             title_font: File name of font to use
             title_font_size: Size of title font
             normal_font: File name of font to use
             normal_font_size: Size of normal font
             errors: Array reference to the bins to analyzie
             bins: Array reference of valid bins to include, defaults to total
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
                 paired_overlap:           Include Paired clone pairs that overlap.
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
                 paired_nonsyntenous:      Include Paired-NonSyntenous type clone pairs.
                 paired:                   Include Paired-Syntenous and Paired-NonSyntenous type clone pairs.
                 total:                    Include all reads.
             colors: Array reference of colors to use for the above categories
             low: Lowest value NtID to plot, default 50
             high: Highest value NtID to plot, default 100

=cut

sub synteny_size_deviation_graph {
  my $self = shift;
  my %params = check_parameters (
    params   => \@_,
    type     => 'graphics',
    defaults => {
      file_name       => 'synteny_size_deviation_graph.gif',
      legend_location => 'bottom',
      legend_justify  => 'center',
      width           => 900,
      height          => 500,
      low             => 50,
      high            => 100
    }
  );
  my %reads = $self->{pigeon_data}->reads(%params);
  my (@data, @legend);
  my (@synteny_counter, @nonsynteny_counter);
  my $high_value = 0;
  my $yaxis_step = 10;
  # Get Original Synteny Error
  my $original_error = $self->{pigeon_data}->synteny_error();
  # Change Synteny Error and count types.
  for (my $i = 0; $i < @{$params{errors}}; $i++) {
    $data[0][$i] = ${$params{errors}}[$i] * 100;
    $self->{pigeon_data}->synteny_error(error => ${$params{errors}}[$i]);
    %reads = $self->{pigeon_data}->reads(%params);
    for (my $j = 1; $j < @{$params{bins}}; $j++) {
      $synteny_counter[$j] = 0;
      $nonsynteny_counter[$j] = 0;
      foreach my $id (keys %reads) {
        if (($reads{$id}{type} eq 'paired_good_good' ||
             $reads{$id}{type} eq 'paired_normal_good' ||
             $reads{$id}{type} eq 'paired_antinormal_good' ||
             $reads{$id}{type} eq 'paired_outie_good') && 
            ($reads{$id}{bin} eq ${$params{bins}}[$j])
           ) {
          $synteny_counter[$j] ++;
        }
        elsif ($reads{$id}{type} ne 'paired_na' && $reads{$id}{bin} eq ${$params{bins}}[$j]) {
          $nonsynteny_counter[$j] ++;
        }
      }
      if ($synteny_counter[$j] > 0) {
        $data[$j][$i] = $synteny_counter[$j] / ($synteny_counter[$j] + $nonsynteny_counter[$j]) * 100;
        if ($data[$j][$i] > $high_value) {
          $high_value = $data[$j][$i];
        }
      }
      else {
        $data[$j][$i] = 0;
      }
    }
  }
  # Restore Original Synteny Error.
  $self->{pigeon_data}->synteny_error(error => $original_error);
  for (my $i = 0; $i < @{$params{bins}}; $i++) {
    if ($self->{pigeon_data}->long_description(bin => ${$params{bins}}[$i])) {
      $legend[$i] = $self->{pigeon_data}->long_description(bin => ${$params{bins}}[$i]);
    }
    else {
      $legend[$i] = ${$params{bins}}[$i];
    }
  }
  # Set Y axis max by rounding highest value up to nearest $yaxis_step
  if ($high_value == 0) {
    $high_value = $yaxis_step;
  }
  $high_value = ceil($high_value / $yaxis_step) * $yaxis_step;
  $self->{gd}->drawLineGraph (
    data              => \@data,
    dataColors        => $params{colors},
    legend            => \@legend,
    legendTitle       => '',
    xAxisTitle        => '% Deviation from Size',
    yAxisTitle        => 'Frequency (%)',
    xLabelSkip        => 1,
    yLabelSkip        => 1,
    maximumValue      => $high_value,
    width             => $params{width},
    height            => $params{height},
    fileName          => $params{file_name},
    backgroundColor   => 'white',
    title             => $params{title},
    titleAlignment    => $params{title_justify},
    titleFont         => $params{title_font},
    titleFontSize     => $params{title_font_size},
    titleColor        => 'black',
    subTitle          => '',
    subTitleAlignment => $params{title_justify},
    subTitleFont      => $params{normal_font},
    subTitleFontSize  => $params{normal_font_size},
    subTitleColor     => 'black',
    labelFont         => $params{normal_font},
    labelFontSize     => $params{normal_font_size},
    labelColor        => 'black',
    legendType        => 'classic',
    legendLocation    => $params{legend_location},
    legendAlignment   => $params{legend_justify},
    legendFont        => $params{normal_font},
    legendFontSize    => $params{normal_font_size},
    legendColor       => 'black',
    cumulate          => 0
  );
}

=head2 rank_abundance_graph

  Title    : rank_abundance_graph
  Usage    : $graph->rank_abundance_graph(
               bin => 'syna',
               file_name => 'rank_abundance_graph.gif'
             );
  Function : Creates a graph of the abundance of reads for each bin provided.
  Args     : file_name: File name, defaults to 'rank_abundance_graph.gif'
             title: Title of this graphic, defaults to 'Rank Abundance Graph'
             title_justify: left, center, right, default center
             title_font: File name of font to use
             title_font_size: Size of title font
             normal_font: File name of font to use
             normal_font_size: Size of normal font
             bins: Array reference of valid bins to include, defaults to total
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
                 paired_overlap:           Include Paired clone pairs that overlap.
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
                 paired_nonsyntenous:      Include Paired-NonSyntenous type clone pairs.
                 paired:                   Include Paired-Syntenous and Paired-NonSyntenous type clone pairs.
                 total:                    Include all reads.
             colors: Array reference of colors to use for the above categories

=cut

sub rank_abundance_graph {
  my $self = shift;
  my %params = check_parameters (
    params   => \@_,
    type     => 'graphics',
    defaults => {
      file_name       => 'rank_abundance_graph.gif',
      legend_location => 'bottom',
      legend_justify  => 'center',
      width           => 1300,
      height          => 600
    }
  );
  my %reads = $self->{pigeon_data}->reads (%params);
  my @data = ();
  my $counter = 0;
  my $col_counter = 0;
  my @high_value;
  my $high_value = 0;
  my @colors = ();
  # Count the number of reads at each Percent ID from 50 to 100 in each bin, metagenome, and other inputs.
  foreach my $bin (@{$params{bins}}) {
    $data[0][$col_counter] = $self->{pigeon_data}->short_description (bin => $bin);
    for (my $ntid=1; $ntid<=52; $ntid++) {
      $data[$ntid][$col_counter] = 0;
    }
    my $bin_counter = 0;
    foreach my $id (keys %reads) {
      if (($reads{$id}{bin} eq $bin)) {
        my $ntid = int ($reads{$id}{percent_identity});
        if ($ntid < 50) {
          $ntid = 52;
        }
        else {
          $ntid = 51 - ($ntid - 50)
        }
        $data[$ntid][$col_counter] ++;
        $bin_counter ++;
      }
    }
    $counter += $bin_counter;
    $col_counter ++;
  }
  $high_value = 0;
  # Convert each count into percent of total
  for (my $x = 0; $x < $col_counter; $x ++) {
    for (my $y = 1; $y <= 52; $y ++) {
      if ($counter > 0) {
        $data[$y][$x] = $data[$y][$x] / $counter * 100;
      }
      else {
        $data[$y][$x] = 0;
      }
      $high_value[$x] += $data[$y][$x]; 
    }
    if ($high_value[$x] > $high_value) {
      $high_value = $high_value[$x];
    }
  }
  # Set Y axis max by rounding highest value up to nearest 10
  $high_value = ceil ($high_value / 10) * 10;
  # Create array of colors to use and setup the legend
  for (my $i = 0; $i <= 51; $i ++) {
    # @colors array has a gradiant of 51 colors from black (#000000) to gray (#666666)
    $colors[$i] = '#' . sprintf ("%.2X", $i * 4) . sprintf ("%.2X", $i * 4) . sprintf ("%.2X", $i * 4);
  }
  # Draw Graph
  $self->{gd}->drawBarGraph (
    data              => \@data,
    dataColors        => \@colors,
    legend            => ['100 %', '75 %', '50 %'],
    legendTitle       => '% nt Identity',
    xAxisTitle        => '',
    yAxisTitle        => 'Frequency (%)',
    xLabelSkip        => 1,
    yLabelSkip        => 1,
    maximumValue      => $high_value,
    width             => $params{width},
    height            => $params{height},
    fileName          => $params{file_name},
    backgroundColor   => 'white',
    title             => $params{title},
    titleAlignment    => $params{title_justify},
    titleFont         => $params{title_font},
    titleFontSize     => $params{title_font_size},
    titleColor        => 'black',
    subTitle          => undef,
    subTitleAlignment => $params{title_justify},
    subTitleFont      => $params{normal_font},
    subTitleFontSize  => $params{normal_font_size},
    subTitleColor     => 'black',
    labelFont         => $params{normal_font},
    labelFontSize     => $params{normal_font_size},
    labelColor        => 'black',
    legendType        => 'gradient',
    legendLocation    => $params{legend_location},
    legendAlignment   => $params{legend_justify},
    legendFont        => $params{normal_font},
    legendFontSize    => $params{normal_font_size},
    legendColor       => 'black',
    cumulate          => 1
  );
}

=head2 snp_location_graph

  Title    : snp_location_graph
  Usage    :
  Function : Creates a graphic displaying the location of SNPs in the given fasta.
  Args     : file_name        - File name, defaults to 'snp_location_graph.gif'.
             width            - Width of this graphic.
             height           - Height of this graphic.
             titles           - Title of this graphic.
             title_justify    - left, center, right, default center.
             title_font       - File name of font to use.
             title_font_size  - Size of title font.
             normal_font      - File name of font to use.
             normal_font_size - Size of normal font.
             legend           - Array reference to the legend, defaults to calculated.
             legend_location  - Location to draw the legend: top, bottom, or none.
             legend_justify   - Justify of the legend: left, center, right.
             fasta            - Pigeon::Fasta object.
             start            - The start position of the sequence.
             end              - The end position of the sequence.
             categories       - Array reference of categories to include.
             colors           - Array reference of colors to use for the above categories
             pixel_size       - Array reference to the pixel size use to draw the data in each of the above categories.
             x_labels         - Labels to draw on the X axis.
             y_labels         - Labels to draw on the Y axis.
             xAxisLocation       - Location to draw the X labels.
             yAxisLocation       - Location to draw the Y labels.
             x_label_location - Array reference of locations to draw the labels on the X axis.
             y_label_location - Array reference of locations to draw the labels on the Y axis.
             x_label_rotation - The degrees to rotate the text label along the X axis.
             y_label_rotaion  - The degrees to rotate the text label along the Y axis.
             x_long_tics      - Display long tics on the X axis, 0 disable, 1 enable, default 0.
             y_long_tics      - Display long tics on the Y axis, 0 disable, 1 enable, default 0.

=cut

sub snp_location_graph {
  my $self = shift;
  my %params = check_parameters (
    params   => \@_,
    type     => 'graphics',
    defaults => {
      file_name => 'snp_location_graph.gif',
      width            => 1300,
      height           => 600,
      normal_font_size => 22,
      title_font_size  => 27
    }
  );
  my ($snp, $counter, $data);
  # Grab the reference sequence from the fasta data.
  my @seqs = $params{fasta}->getAll();
  my $ref = shift @seqs;
  # Set default values for undefined parameters.
  if (not defined $params{start}) {
    $params{start} = 0;
  }
  if (not defined $params{end}) {
    $params{end} = length $ref->{sequence};
  }
  if (not defined $params{categories}) {
    $params{categories} = ['null'];
  }
  # Compare each nucleotide in the reference sequence to the remaining sequences in the fasta data.
  my $i = 1;
  foreach my $seq (@seqs) {
    # Initialize the SNP counter for this sequence.
    $counter->{$seq->{identifier}} = 0;
    # Determine the type of this sequence.
    my $type = $seq->{meta}{type};
    if (not defined $type || not contains (item => $type, list => $params{categories})) {
      $type = 'null';
    }
    # Count the SNPs between start and end.
    for (my $j = $params{start}; $j < $params{end}; $j ++) {
      # Check if this nucleotide matches the reference.
      my $ref_nuc = substr $ref->{sequence}, $j, 1;
      my $nuc = substr $seq->{sequence}, $j, 1;
      if (not nucleotide_is_equal($ref_nuc, $nuc)) {
        push @{$snp->{$type}}, [[$j, $i]];
        $counter->{$seq->{identifier}} ++;
      }
    }
    $i ++;
  }
  # Create the data structure for the graphing program.
  foreach my $category (@{$params{categories}}) {
    push @{$data}, $snp->{$category};
  }
  # Figure out the maximum value that the Y axis should hold.
  my $ymax = @seqs;
  if ($ymax < 1) {
    $ymax = 1;
  }
  $ymax ++;
  # Calculate the location and labels for the X and Y axes if they weren't supplied.
  if (not defined $params{y_label_location}) {
    for (my $i = 0; $i <= $ymax; $i ++) {
      push @{$params{y_label_location}}, $i;
    }
  }
  if (not defined $params{y_labels}) {
    push @{$params{y_labels}}, '';
    foreach my $seq (@seqs) {
      my $label = $seq->{identifier};
      if (defined $seq->{meta}{st}) {
        $label .= sprintf "   ST: %2d", $seq->{meta}{st};
      }
      $label .= sprintf " - %2d SNPs", $counter->{$seq->{identifier}};
      push @{$params{y_labels}}, $label;
    }
    push @{$params{y_labels}}, '';
  }
  if (not defined $params{x_label_location}) {
    $params{x_label_location} = [$params{start}, $params{end}];
  }
  if (not defined $params{x_labels}) {
    $params{x_labels} = [$params{start}, $params{end}];
  }
  # Draw Graph
  $self->{image}->plot (
    fileName           => $params{file_name},
    data               => $data,
    dataColors         => $params{colors},
    width              => $params{width},
    height             => $params{height},
    titles             => $params{titles},
    titleAlignment     => $params{title_justify},
    legend             => $params{legend},
    legendLocation     => $params{legend_location},
    legendAlignment    => $params{legend_justify},
    color              => 'black',
    backgroundColor    => 'white',
    titleFont          => $params{title_font},
    titleFontSize      => $params{title_font_size},
    titleColor         => 'black',
    normalFont         => $params{normal_font},
    normalFontSize     => $params{normal_font_size},
    normalFontColor    => 'black',
    pixelSize          => $params{pixel_size},
    xMinimumValue      => $params{start},
    xMaximumValue      => $params{end},
    xAxisTitle         => "Position on the gene",
    xAxisLocation      => $params{x_location},
    xAxisLabels        => $params{x_labels},
    xAxisLabelLocation => $params{x_label_location},
    xAxisLabelRotation => $params{x_label_rotation},
    xAxisLongTics      => $params{x_long_tics},
    yMinimumValue      => 0,
    yMaximumValue      => $ymax,
    yAxisTitle         => "Sequence",
    yAxisLocation      => $params{y_location},
    yAxisLabels        => $params{y_labels},
    yAxisLabelLocation => $params{y_label_location},
    yAxisLabelRotation => $params{y_label_rotation},
    yAxisLongTics      => $params{y_long_tics}
  );
}

=head2 tiled_genome_graph

  Title    : tiled_genome_graph
  Usage    : $graph->tiled_genome_graph(
               bins => ['syna'],
               file_name => 'tiled_genome_graph.gif'
             );
  Function : Creates a Tiled Genome Graph for the provided bins, etc.
  Args     : file_name: File name, defaults to 'tiled_genome_graph.gif'
             width: Width of this graphic
             height: Height of this graphic
             titles: Title of this graphic
             title_justify: left, center, right, default center
             title_font: File name of font to use
             title_font_size: Size of title font
             normal_font: File name of font to use
             normal_font_size: Size of normal font
             legend : Array reference to the legend, defaults to calculated.
             legend_location: Location to draw the legend: top, bottom, or none
             legend_justify: Justify of the legend: left, center, right
             bins: Array reference of valid bins to include, defaults to total
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
                 paired_overlap:           Include Paired clone pairs that overlap.
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
                 paired_nonsyntenous:      Include Paired-NonSyntenous type clone pairs.
                 paired:                   Include Paired-Syntenous and Paired-NonSyntenous type clone pairs.
                 total:                    Include all reads.
             colors: Array reference of colors to use for each category
             pixel_size: Array reference of pixel sizes to use for each category.
             connected: Array reference of connected booleans to use for each category.
               0: Do not connect ends
               1: Draw a connecting line between ends

=cut

sub tiled_genome_graph {
  my $self = shift;
  my %params = check_parameters (
    params   => \@_,
    type     => 'graphics',
    defaults => {
      file_name        => 'tiled_genome_graph.gif',
      width            => 1300,
      height           => 600,
      normal_font_size => 22,
      title_font_size  => 27
    }
  );
  my %reads = $self->{pigeon_data}->reads(%params);
  my $genome_size = 0;
  # Find the largest genome, and setup the titles for for each bin, category, and metagenome combo.
  my %title;
  foreach my $bin (@{$params{bins}}) {
    if ($self->{pigeon_data}->genome_size(bin => $bin) > $genome_size) {
      $genome_size = $self->{pigeon_data}->genome_size(bin => $bin);
    }
    foreach my $category (@{$params{categories}}) {
      foreach my $metagenome (@{$params{metagenomes}}) {
        if (@{$params{bins}} > 1 || (@{$params{metagenomes}} == 1 && @{$params{categories}} == 1)) {
          $title{$metagenome}{$category}{$bin} .= $self->{pigeon_data}->long_description(bin => $bin) . ' ';
        }
        if (@{$params{metagenomes}} > 1) {
          $title{$metagenome}{$category}{$bin} .= $self->{pigeon_data}->long_description(bin => $metagenome) . ' ';
        }
        if (@{$params{categories}} > 1) {
          $title{$metagenome}{$category}{$bin} .= $self->{pigeon_data}->long_description(bin => $category) . ' ';
        }
        $title{$metagenome}{$category}{$bin} .= 'Reads ';
      }
    }
  }
  # Setup the data for each bin, category, and metagenome combo.
  my (@data, @legend);
  my $i = 0;
  my $y_value = 0;
  foreach my $bin (@{$params{bins}}) {
    foreach my $category (@{$params{categories}}) {
      foreach my $metagenome (@{$params{metagenomes}}) {
        my $set;
        my $counter = 0;
        my @used;
        foreach my $id (sort_by_location %reads) {
          if (
            test_categories(item => $reads{$id}{type}, list => [$category]) &&
            ($reads{$id}{bin} eq $bin || $bin eq 'total') &&
            ($reads{$id}{metagenome} eq $metagenome || $metagenome eq 'total') &&
            not contains (item => $id, list => \@used)
          ) {
            $counter += 2;
            $y_value ++;
            my %read = (
              genome_size    => $genome_size,
              connected      => $params{connected}->[$i],
              type           => $reads{$id}{type},
              start_start    => $reads{$id}{subject_start},
              start_end      => $reads{$id}{subject_end},
              start_identity => $y_value
            );
            if (
              (defined $reads{$id}{clone_pair} && defined $reads{$reads{$id}{clone_pair}}) && 
              ($reads{$id}{type} =~ /^paired/ || $reads{$id}{type} =~ /^unpaired/)
            ) {
              $read{end_start}    = $reads{$reads{$id}{clone_pair}}{subject_start};
              $read{end_end}      = $reads{$reads{$id}{clone_pair}}{subject_end};
              $read{end_identity} = $y_value;
              push @used, $reads{$id}{clone_pair};
            }
            push @{$set}, $self->_translate_data(%read);
          }
        }
        # Add space between categories.
        $y_value += 2;
        # Use the user provided legend if available, otherwise use the generated one.
        my $legend;
        if (defined $params{legend} && defined $params{legend}->[$i]) {
          $legend = $params{legend}->[$i] . ' ';
        }
        else {
          $legend = $title{$metagenome}{$category}{$bin};
        }
        # Add this set to the data and legend.
        $data[$i] = $set;
        $legend[$i] =  $legend . '(' . $counter . ')';
        $i ++;
      }
    }
  }
  if ($y_value < 1) {
    $y_value = 1;
  }
  # Setup the tic marks and labels.
  if (not defined $params{x_label_location}) {
    $params{x_label_location} = [
      0,
      round ($genome_size * 0.25),
      round ($genome_size * 0.50),
      round ($genome_size  * 0.75),
      $genome_size
    ];
  }
  if (not defined $params{x_labels}) {
    $params{x_labels} = [
      '0 kbp',
      '',
      round ($genome_size / 1000 * 0.50) . ' kbp',
      '',
      round ($genome_size / 1000) . ' kbp'
    ];
  }
  my $num_labels = 10;
  my $label_skip = ceil ($y_value / $num_labels);
  my (@y_labels, @y_label_location);
  for (my $i = 0; $i <= $num_labels; $i ++) {
    push @y_labels, $i * $label_skip;
    push @y_label_location, $i * $label_skip;
  }
  # Draw Graph
  $self->{image}->plot (
    fileName          => $params{file_name},
    data               => \@data,
    dataColors         => $params{colors},
    width              => $params{width},
    height             => $params{height},
    title              => $params{title},
    titleAlignment     => $params{title_justify},
    titleFont          => $params{title_font},
    titleFontSize      => $params{title_font_size},
    titleColor         => 'black',
    subTitle           => $params{subTitle},
    subTitleAlignment  => $params{subTitleAlignment},
    subTitleFontSize   => $params{subTitleFontSize},
    subTitleColor      => $params{subTitleFontColor},
    legend             => \@legend,
    legendLocation     => $params{legend_location},
    legendAlignment    => $params{legend_justify},

    color              => 'black',
    backgroundColor    => 'white',
    normalFont         => $params{normal_font},
    normalFontSize     => $params{normal_font_size},
    normalFontColor    => 'black',

    pixelSize          => $params{pixel_size},
    xMinimumValue      => 0,
    xMaximumValue      => $genome_size,
    xAxisTitle         => 'Position on the genome',
    xAxisLocation      => 'top',
    xAxisLabels        => $params{x_labels},
    xAxisLabelLocation => $params{x_label_location},
    xAxisLabelRotation => $params{x_label_rotation},
    xAxisLongTics      => $params{x_long_tics},
    yMinimumValue      => 0,
    yMaximumValue      => $label_skip * $num_labels,
    yAxisTitle         => 'Clone Pairs',
    yAxisLocation      => 'left',
    yAxisLabels        => \@y_labels,
    yAxisLabelLocation => \@y_label_location,
    yAxisLabelRotation => $params{y_label_rotation},
    yAxisLongTics      => $params{y_long_tics}
  );
}

=head2 genome_graph

  Title    : genome_graph
  Usage    : $graph->genome_graph(
               bins => ['syna'],
               file_name => 'genome_graph.gif'
             );
  Function : Creates a Genome Graph for the provided bins, etc.
  Args     : file_name: File name, defaults to 'genome_graph.gif'
             width: Width of this graphic
             height: Height of this graphic
             titles: Title of this graphic
             title_justify: left, center, right, default center
             title_font: File name of font to use
             title_font_size: Size of title font
             normal_font: File name of font to use
             normal_font_size: Size of normal font
             legend : Array reference to the legend, defaults to calculated.
             legend_location: Location to draw the legend: top, bottom, or none
             legend_justify: Justify of the legend: left, center, right
             bins: Array reference of valid bins to include, defaults to total
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
                 paired_overlap:           Include Paired clone pairs that overlap.
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
                 paired_nonsyntenous:      Include Paired-NonSyntenous type clone pairs.
                 paired:                   Include Paired-Syntenous and Paired-NonSyntenous type clone pairs.
                 total:                    Include all reads.
             colors: Array reference of colors to use for each category
             pixel_size: Array reference of pixel sizes to use for each category.
             connected: Array reference of connected booleans to use for each category.
               0: Do not connect ends
               1: Draw a connecting line between ends

=cut

sub genome_graph {
  my $self = shift;
  my %params = check_parameters (
    params   => \@_,
    type     => 'graphics',
    defaults => {
      file_name        => 'genome_graph.gif',
      width            => 1300,
      height           => 600,
      low              => 50,
      high             => 100,
      normal_font_size => 22,
      title_font_size  => 27

    }
  );
  my %reads = $self->{pigeon_data}->reads(%params);
  my $genome_size = 0;
  # Find the largest genome, and setup the titles for for each bin, category, and metagenome combo.
  my %title;
  foreach my $bin (@{$params{bins}}) {
    if ($self->{pigeon_data}->genome_size(bin => $bin) > $genome_size) {
      $genome_size = $self->{pigeon_data}->genome_size(bin => $bin);
    }
    foreach my $category (@{$params{categories}}) {
      foreach my $metagenome (@{$params{metagenomes}}) {
        if (@{$params{bins}} > 1 || (@{$params{metagenomes}} == 1 && @{$params{categories}} == 1)) {
          $title{$metagenome}{$category}{$bin} .= $self->{pigeon_data}->long_description(bin => $bin) . ' ';
        }
        if (@{$params{metagenomes}} > 1) {
          $title{$metagenome}{$category}{$bin} .= $self->{pigeon_data}->long_description(bin => $metagenome) . ' ';
        }
        if (@{$params{categories}} > 1) {
          $title{$metagenome}{$category}{$bin} .= $self->{pigeon_data}->long_description(bin => $category) . ' ';
        }
        $title{$metagenome}{$category}{$bin} .= 'Reads ';
      }
    }
  }
  # Setup the data for each bin, category, and metagenome combo.
  my (@data, @legend);
  my $i = 0;
  foreach my $bin (@{$params{bins}}) {
    foreach my $category (@{$params{categories}}) {
      foreach my $metagenome (@{$params{metagenomes}}) {
        my $set;
        my $counter = 0;
        foreach my $id (keys %reads) {
          if (
            test_categories(item => $reads{$id}{type}, list => [$category]) &&
            ($reads{$id}{bin} eq $bin || $bin eq 'total') &&
            ($reads{$id}{metagenome} eq $metagenome || $metagenome eq 'total')
         ) {
            $counter ++;
            my %read = (
              genome_size    => $genome_size,
              connected      => $params{connected}->[$i],
              type           => $reads{$id}{type},
              start_start    => $reads{$id}{subject_start},
              start_end      => $reads{$id}{subject_end},
              start_identity => $reads{$id}{percent_identity}
            );
            if ((defined $reads{$id}{clone_pair} && defined $reads{$reads{$id}{clone_pair}}) && 
                ($reads{$id}{type} =~ /^paired/ || $reads{$id}{type} =~ /^unpaired/)) {
              $read{end_start}    = $reads{$reads{$id}{clone_pair}}{subject_start};
              $read{end_end}      = $reads{$reads{$id}{clone_pair}}{subject_end};
              $read{end_identity} = $reads{$reads{$id}{clone_pair}}{percent_identity};
            }
            push @{$set}, $self->_translate_data(%read);
          }
        }
        # Use the user provided legend if available, otherwise use the generated one.
        my $legend;
        if (defined $params{legend} && defined $params{legend}->[$i]) {
          $legend = $params{legend}->[$i] . ' ';
        }
        else {
          $legend = $title{$metagenome}{$category}{$bin};
        }
        # Add this set to the data and legend.
        $data[$i] = $set;
        $legend[$i] =  $legend . '(' . $counter . ')';
        $i ++;
      }
    }
  }
  # Setup the tic marks and labels.
  if (not defined $params{x_label_location}) {
    $params{x_label_location} = [
      0,
      round ($genome_size * 0.25),
      round ($genome_size * 0.50),
      round ($genome_size * 0.75),
      $genome_size
    ];
  }
  if (not defined $params{x_labels}) {
    $params{x_labels} = [
      '0 kbp',
      '',
      round ($genome_size / 1000 * 0.50) . ' kbp',
      '',
      round ($genome_size / 1000) . ' kbp'
    ];
  }
  my @y_labels = (
    $params{low},
    '',
    $params{high}
  );
  my @y_label_location =(
    $params{low},
    round (($params{high} + $params{low}) / 2),
    $params{high}
  );
  # Draw Graph
  $self->{image}->plot (
    fileName           => $params{file_name},
    data               => \@data,
    dataColors         => $params{colors},
    width              => $params{width},
    height             => $params{height},
    titles             => $params{titles},
    titleAlignment     => $params{title_justify},
    legend             => \@legend,
    legendLocation     => $params{legend_location},
    legendAlignment    => $params{legend_justify},
    color              => 'black',
    backgroundColor    => 'white',
    titleFont          => $params{title_font},
    titleFontSize      => $params{title_font_size},
    titleColor         => 'black',
    normalFont         => $params{normal_font},
    normalFontSize     => $params{normal_font_size},
    normalFontColor    => 'black',
    pixelSize          => $params{pixel_size},
    xMinimumValue      => 0,
    xMaximumValue      => $genome_size,
    xAxisTitle         => 'Position on the genome',
    xAxisLocation      => 'top',
    xAxisLabels        => $params{x_labels},
    xAxisLabelLocation => $params{x_label_location},
    xAxisLabelRotation => $params{x_label_rotation},
    xAxisLongTics      => $params{x_long_tics},
    yMinimumValue      => $params{low},
    yMaximumValue      => $params{high},
    yAxisTitle         => '% nt Identity',
    yAxisLocation      => 'left',
    yAxisLabels        => \@y_labels,
    yAxisLabelLocation => \@y_label_location,
    yAxisLabelRotation => $params{y_label_rotation},
    yAxisLongTics      => $params{y_long_tics}
  );
}

=head2 forced_genome_graph

  Title    : forced_genome_graph
  Usage    : $graph->forced_genome_graph(
               bin => 'syna',
               file_name => 'forced_genome_graph.gif'
             );
  Function : Creates a genome mapped graph where all reads have been forced fall into the given forced bin,
             then further broken up by the metagenome the sample was taken from and the bin tha the read
             would fall into given more choices.  Each read is posistioned based on its location on the
             forced genome, and its percent nucleotide identity.
  Args     : file_name: File name, defaults to 'forced_genome_graph.gif'
             title: Title of this graphic, defaults to 'Forced Genome Graph'
             title_justify: left, center, right, default center
             title_font: File name of font to use
             title_font_size: Size of title font
             normal_font: File name of font to use
             normal_font_size: Size of normal font
             forced_bins: Array reference of valid forced bins
             bins: Array reference of valid bins to include, defaults to total
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
                 paired_overlap:           Include Paired clone pairs that overlap.
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
                 paired_nonsyntenous:      Include Paired-NonSyntenous type clone pairs.
                 paired:                   Include Paired-Syntenous and Paired-NonSyntenous type clone pairs.
                 total:                    Include all reads.
             colors: Array reference of colors to use for each category
             pixel_size: Array reference of pixel sizes to use for each category.
             connected: Array reference of connected booleans to use for each category.
               0: Do not connect ends
               1: Draw a connecting line between ends

=cut

sub forced_genome_graph {
  my $self = shift;
  my %params = check_parameters (
    params   => \@_,
    type     => 'graphics',
    defaults => {
      file_name        => 'forced_genome_graph.gif',
      width            => 1300,
      height           => 600,
      low              => 50,
      high             => 100,
      normal_font_size => 22,
      title_font_size  => 27
    }
  );
  my %reads = $self->{pigeon_data}->reads();
  my %forced = $self->{pigeon_data}->forced(%params);
  my $genome_size = 0;
  # Find largest genome size in the forced_bins
  foreach my $forced_bin (@{$params{forced_bins}}) {
    if ($self->{pigeon_data}->genome_size(bin => $forced_bin) > $genome_size) {
      $genome_size = $self->{pigeon_data}->genome_size(bin => $forced_bin);
    }
  }
  my ($data, $legend);
  foreach my $category (@{$params{categories}}) {
    my $set;
    my $counter = 0;
    foreach my $forced_bin (@{$params{forced_bins}}) {
      foreach my $id (keys %{$forced{$forced_bin}}) {
        if (test_categories(item => $forced{$forced_bin}{$id}{type}, list => [$category])) {
          $counter ++;
          my %read = (
            genome_size    => $genome_size,
            connected      => $params{connected},
            type           => 'nopair',
            start_start    => $forced{$forced_bin}{$id}{subject_start},
            start_end      => $forced{$forced_bin}{$id}{subject_end},
            start_identity => $forced{$forced_bin}{$id}{percent_identity}
          );
          if ((defined $reads{$id}{clone_pair} && defined $forced{$forced_bin}{$reads{$id}{clone_pair}}) && 
              ($forced{$forced_bin}{$id}{type} =~ /^paired/ || $forced{$forced_bin}{$id}{type} =~ /^unpaired/)) {
            $read{type}         = $forced{$forced_bin}{$id}{type};
            $read{end_start}    = $forced{$forced_bin}{$reads{$id}{clone_pair}}{subject_start};
            $read{end_end}      = $forced{$forced_bin}{$reads{$id}{clone_pair}}{subject_end};
            $read{end_identity} = $forced{$forced_bin}{$reads{$id}{clone_pair}}{percent_identity};
          }        
          push @{$set}, $self->_translate_data(%read);
        }
      }
    }
    push @{$data}, $set;
    push @{$legend}, $self->{pigeon_data}->long_description(bin => $category) . ' Reads (' . $counter . ')';
  }
  # Setup the tic marks and labels.
  if (not defined $params{x_label_location}) {
    $params{x_label_location} = [
      0,
      round ($genome_size * 0.25),
      round ($genome_size * 0.50),
      round ($genome_size * 0.75),
      $genome_size
    ];
  }
  if (not defined $params{x_labels}) {
    $params{x_labels} = [
      '0 kbp',
      '',
      round ($genome_size / 1000 * 0.50) . ' kbp',
      '',
      round ($genome_size / 1000) . ' kbp'
    ];
  }
  my @y_labels = (
    $params{low},
    '',
    $params{high}
  );
  my @y_label_location =(
    $params{low},
    round (($params{high} + $params{low}) / 2),
    $params{high}
  );
  # Draw Graph
  $self->{image}->plot (
    fileName           => $params{file_name},
    data               => $data,
    dataColors         => $params{colors},
    width              => $params{width},
    height             => $params{height},
    titles             => $params{titles},
    titleAlignment     => $params{title_justify},
    legend             => $legend,
    legendLocation     => $params{legend_location},
    legendAlignment    => $params{legend_justify},
    color              => 'black',
    backgroundColor    => 'white',
    titleFont          => $params{title_font},
    titleFontSize      => $params{title_font_size},
    titleColor         => 'black',
    normalFont         => $params{normal_font},
    normalFontSize     => $params{normal_font_size},
    normalFontColor    => 'black',
    pixelPize          => $params{pixel_size},
    xMinimumValue      => 0,
    xMaximumValue      => $genome_size,
    xAxisTitle         => 'Position on the genome',
    xAxisLocation      => 'top',
    xAxisLabels        => $params{x_labels},
    xAxisLabelLocation => $params{x_label_location},
    xAxisLabelRotation => $params{x_label_rotation},
    xAxisLongTics      => $params{x_long_tics},
    yMinimumValue      => $params{low},
    yMaximumValue      => $params{high},
    yAxisTitle         => '% nt Identity',
    yAxisLocation      => 'left',
    yAxisLabels        => \@y_labels,
    yAxisLabelLocation => \@y_label_location,
    yAxisLabelRotation => $params{y_label_rotation},
    yAxisLongTics      => $params{y_long_tics}
  );
}

=head2 _translate_data

  Title    : _translate_data
  Usage    : private
  Function : Translates the data.
  Return   : The translated data.
  Args     : connected: 1 to connect the two ends, 0 if not.
             type: Read type.
             genome_size: Size of the genome, used to check for a wrap around.
             start_start: Start position of the first read.
             start_end: End position of the first read.
             start_identity: Identity of the first read.
             end_start: Start position of the second read.
             end_end: End position of the second read.
             end_identity: Identity of the second read.

=cut

sub _translate_data {
  my $self = shift;
  my %params = @_;
  my @line;
  if ($params{type} =~ /^paired/) {
    if ($params{connected}) {
      if (abs($params{start_end} - $params{end_start}) <= $params{genome_size} / 2) {
        @line = ([[$params{start_start}, $params{start_identity}],
                  [$params{start_end}, $params{start_identity}],
                  [$params{end_start}, $params{end_identity}],
                  [$params{end_end}, $params{end_identity}]]);
      }
      else {
        my ($slope, $intercept);
        if ($params{start_end} > $params{end_start}) {
          $slope = ($params{end_identity} - $params{start_identity}) / ($params{genome_size} - $params{start_end} + $params{end_start});
          $intercept = $params{end_identity} - $slope * $params{end_start};
          @line = ([[$params{start_start}, $params{start_identity}],
                    [$params{start_end}, $params{start_identity}],
                    [$params{genome_size}, $intercept]],
                   [[0, $intercept],
                    [$params{end_start}, $params{end_identity}],
                    [$params{end_end}, $params{end_identity}]]);
        }
        else {
          $slope = ($params{start_identity} - $params{end_identity}) / ($params{genome_size} - $params{end_start} + $params{start_end});
          $intercept = $params{start_identity} - $slope * $params{start_end};
          @line = ([[$params{end_end}, $params{end_identity}],
                    [$params{end_start}, $params{end_identity}],
                    [$params{genome_size}, $intercept]],
                   [[0, $intercept],
                    [$params{start_end}, $params{start_identity}],
                    [$params{start_start}, $params{start_identity}]]);
        }
      }
    }
    else {
      @line = ([[$params{start_start}, $params{start_identity}],
                [$params{start_end}, $params{start_identity}]],
               [[$params{end_start}, $params{end_identity}],
                [$params{end_end}, $params{end_identity}]]);
    }
  }
  elsif ($params{type} =~/^unpaired/ || $params{type} =~ /^nopair/) {
    @line = ([[$params{start_start}, $params{start_identity}],
              [$params{start_end}, $params{start_identity}]]);
  }
  return @line;
}

1;
__END__


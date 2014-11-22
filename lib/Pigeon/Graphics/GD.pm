=head1 NAME

  Pigeon::Graphics::GD - GD specific methods used in Pigeon::Graphics.

=head1 SYNOPSIS

  Private usage by Pigeon.

=head1 DESCRIPTION

  This package holds GD specific methods used in Pigeon::Graphics.

=head1 DEPENDENCIES

  This package depends on various packages in the Pigeon hierarchy,
  in addition to GD::Simple, GD::Graph, and POSIX.

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

package Pigeon::Graphics::GD;

use strict;
use warnings;

use Pigeon::Tools qw(:all);
use GD::Simple;
use GD::Graph::bars;
use GD::Graph::lines;
use GD::Graph::points;

use constant TEST_LINE => 'ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890abcdefghijklmnopqrstuvwxyz';

# Private Methods.

my $checkAlignment = sub {
  my $self = shift;
  my %params = @_;
  my $spacer;
  if ($params{alignment} eq 'left') {
    $spacer = 0;
  }
  elsif ($params{alignment} eq 'center') {
    $spacer = ($params{imageWidth} - $params{width}) / 2;

  }
  elsif ($params{alignment} eq 'right') {
    $spacer = $params{imageWidth} - $params{width};
  }
  return $spacer;  
};

my $translateColor = sub {
  my $self = shift;
  my ($color) = @_;
  my @color;
  if (defined $color && substr($color, 0, 1) eq '#') {
    @color = GD::Graph::colour::hex2rgb($color);
  }
  elsif (defined $color && $color eq 'brown') {
    @color = GD::Graph::colour::hex2rgb('#8B4513');
  }
  elsif (defined $color) {
    @color = GD::Graph::colour::_rgb($color);
  }
  else {
    @color = GD::Graph::colour::hex2rgb('#000000');
  }
  return @color;
};


my $drawGraph = sub {
  my $self = shift;
  my %params = @_;
  my $spacerModifier = 1.25;
  # Create a GD object.
  my $gd = new GD::Simple ($params{width}, $params{height});
  # Get Title dimensions.
  my $titleHeight = 0;
  my $titleWidth = 0;
  my $subTitleHeight = 0;
  my $subTitleWidth = 0;
  ($_, $titleWidth, $titleHeight) = GD::Simple->fontMetrics($params{titleFont}, $params{titleFontSize}, $params{title}) if (defined $params{title});
  ($_, $subTitleWidth, $subTitleHeight) = GD::Simple->fontMetrics($params{subTitleFont}, $params{subTitleFontSize}, $params{subTitle}) if (defined $params{subTitle});
  my $titleSpace = $titleHeight * $spacerModifier + $subTitleHeight * $spacerModifier;
  $subTitleHeight += $titleHeight * $spacerModifier;
  # Draw the title.
  my $spacer = 0;
  $spacer = $self->$checkAlignment (
    alignment  => $params{titleAlignment},
    imageWidth => $params{width},
    width      => $titleWidth
  );
  $gd->bgcolor ($params{backgroundColor});
  $gd->fgcolor ($params{titleColor});
  $gd->font ($params{titleFont});
  $gd->fontsize ($params{titleFontSize});
  $gd->moveTo ($spacer, $titleHeight);
  $gd->string ($params{title});
  # Draw the sub-title.
  $spacer = $self->$checkAlignment (
    alignment  => $params{subTitleAlignment},
    imageWidth => $params{width},
    width      => $subTitleWidth
  );
  $gd->fgcolor ($params{subTitleColor});
  $gd->font ($params{subTitleFont});
  $gd->fontsize ($params{subTitleFontSize});
  $gd->moveTo ($spacer, $subTitleHeight);
  $gd->string ($params{subTitle});
  my $graphicTop = $titleSpace;
  my $legendSpace = 0;
  if ($params{legendLocation} ne 'none') {
    # Calculate the height required to draw the legend, based on the type of legend and the font size specified.
    my $legendHeight;
    ($_, $_, $legendHeight) = GD::Simple->fontMetrics($params{legendFont}, $params{legendFontSize}, TEST_LINE);
    $gd->font ($params{legendFont});
    $gd->fontsize ($params{legendFontSize});
    if ($params{legendType} eq 'classic') {
      # Find the maximum width of the legend elements.
      my $maxWidth = 0;
      foreach my $legend (@{$params{legend}}) {
        ($_, my $width, $_) = GD::Simple->fontMetrics($params{legendFont}, $params{legendFontSize}, $legend);
        $maxWidth = $width if ($width > $maxWidth);
      } 
      # Calculate the number of columns that the legend needs.
      my $legendColumns = 0;
      my $legendWidth = 0;
      while (($legendColumns + 1) * ($maxWidth + 2 * $legendHeight) + $legendColumns * 2 * $legendHeight < $params{width}) {
        $legendColumns ++;
        $legendWidth = $legendColumns * ($maxWidth + 2 * $legendHeight) + ($legendColumns - 1) * 2 * $legendHeight;
      }
      if ($legendColumns > @{$params{legend}}) {
        $legendColumns = @{$params{legend}};
      }
      $legendSpace = ceil (@{$params{legend}} / $legendColumns) * $legendHeight * $spacerModifier;
      # Calculate the location to draw the legend.
      my $legendTop;
      if ($params{legendLocation} eq 'top') {
        $legendTop = $titleSpace + $legendHeight;
        $graphicTop = $legendTop + $legendSpace - $legendHeight * $spacerModifier + 1;
      }
      elsif ($params{legendLocation} eq 'bottom') {
        $legendTop = $params{height} - $legendSpace + $legendHeight * $spacerModifier - 1;
        $graphicTop = $titleSpace;
      }
      $spacer = $self->$checkAlignment (
        alignment  => $params{legendAlignment},
        imageWidth => $params{width},
        width      => $legendWidth
      );
      # Draw the legend.
      $gd->fgcolor ($params{legendColor});
      for (my $i = 0; $i < @{$params{legend}}; $i ++) {
        my $top = $legendTop + floor ($i / $legendColumns) * $legendHeight * $spacerModifier;
        my $left = $spacer + ($i % $legendColumns) * ($maxWidth + 2 * $legendHeight);
        if ($legendColumns > 1 and $i % $legendColumns != 0) {
          $left += 2 * $legendHeight;
        }
        # Draw the legend box.
        $gd->bgcolor ($params{dataColors}->[$i]);
        $gd->rectangle ($left, $top, $left + $legendHeight, $top - $legendHeight);
        # Draw the legend string.
        $gd->fgcolor ($params{legendColor});
        $gd->moveTo ($left + 2 * $legendHeight, $top - 3);
        $gd->string ($params{legend}->[$i]);
      }
    }    
    elsif ($params{legendType} eq 'gradient') {
      # Calculate the location to draw the legend.
      ($_, my $legendTitleWidth, my $legendTitleHeight) = GD::Simple->fontMetrics($params{legendFont}, $params{legendFontSize}, $params{legendTitle});
      $legendSpace = 3 * $legendHeight * $spacerModifier + $legendTitleHeight * $spacerModifier;
      my $legendTop;
      if ($params{legendLocation} eq 'top') {
        $legendTop = $titleSpace;
        $graphicTop = $titleSpace + $legendSpace;
      }
      elsif ($params{legendLocation} eq 'bottom') {
        $legendTop = $params{height} - $legendSpace + $legendHeight / $spacerModifier;
        $graphicTop = $titleSpace;
      }
      my $legendWidth = round ($params{width} / 3);
      my $left;
      if ($params{legendAlignment} eq 'center') {
        $left = round ($params{width} - $legendWidth) / 2;
      }
      elsif ($params{legendAlignment} eq 'left') {
        ($_, my $w, $_) = GD::Simple->fontMetrics($params{legendFont}, $params{legendFontSize}, $params{legend}->[0]);
        $left = $w / 2;
      }
      elsif ($params{legendAlignment} eq 'right') {
        ($_, my $w, $_) = GD::Simple->fontMetrics($params{legendFont}, $params{legendFontSize}, $params{legend}->[@{$params{legend}} - 1]);
        $left = $params{width} - $legendWidth - $w / 2;
      }
      # Draw the gradient box using colors stored in dataColors
      my $width = $legendWidth / @{$params{dataColors}};
      for (my $i = 0; $i < @{$params{dataColors}}; $i ++) {
         $gd->fgcolor ($self->$translateColor ($params{dataColors}->[$i]));
         $gd->bgcolor ($self->$translateColor ($params{dataColors}->[$i]));
         $gd->rectangle ($left + $i * $width, $legendTop, $left + ($i + 1) * $width, $legendTop + $legendHeight * $spacerModifier);
      }
      # Draw tic marks and labels below the gradient box for each element stored in legend
      $width = $legendWidth / (@{$params{legend}} - 1);
      $gd->fgcolor ($params{legendColor});
      $gd->bgcolor ($params{backgroundColor});
      for (my $i = 0; $i < @{$params{legend}}; $i ++) {
        $gd->rectangle ($left + $i * $width, $legendTop + $legendHeight * $spacerModifier + 1, $left + $i * $width, $legendTop + $legendHeight * $spacerModifier + 5);
        ($_, my $w, $_) = GD::Simple->fontMetrics($params{legendFont}, $params{legendFontSize}, $params{legend}->[$i]);
        $w = 1 if (not defined $w); 
        $gd->moveTo ($left + $i * $width - $w / 2, $legendTop + 2 * $legendHeight * $spacerModifier);
        $gd->string ($params{legend}->[$i]);
      }
      # Draw the legend title.
      $gd->moveTo ($left + ($legendWidth - $legendTitleWidth) / 2, $legendTop + 3 * $legendHeight * $spacerModifier);
      $gd->string ($params{legendTitle});
    }
  }
  # Create the GD::Graph object.
  my $graph;
  if (lc $params{type} =~ /^line/) {  
    $graph = new GD::Graph::lines ($params{width}, $params{height} - $titleSpace - $legendSpace);
  }
  elsif (lc $params{type} =~ /^bar/) {
    $graph = new GD::Graph::bars ($params{width}, $params{height} - $titleSpace - $legendSpace);
  }
  elsif (lc $params{type} =~ /^point/) {
    $graph = new GD::Graph::points ($params{width}, $params{height} - $titleSpace - $legendSpace);
  }
  $graph->set (
    x_label          => $params{xAxisTitle},
    y_label          => $params{yAxisTitle},
    transparent      => 0,
    dclrs            => $params{dataColors},
    borderclrs       => $params{dataColors},
    bgclr            => $params{backgroundColor},
    fgclr            => $params{labelColor},
    labelclr         => $params{labelColor},
    axislabelclr     => $params{labelColor},
    valuesclr        => $params{labelColor},
    textclr          => $params{labelColor},
    line_width       => 2,
    x_label_skip     => $params{xLabelSkip},
    y_label_skip     => $params{yLabelSkip},
    x_long_ticks     => 0,
    y_long_ticks     => 1,
    y_max_value      => $params{maximumValue},
    y_min_value      => 0,
    y_tick_number    => 5,
    x_label_position => 1/2,
    cumulate         => $params{cumulate}
  ) or die $graph->error;
  $graph->set_x_label_font($params{labelFont}, $params{labelFontSize}) or die $graph->error;
  $graph->set_y_label_font($params{labelFont}, $params{labelFontSize}) or die $graph->error;
  $graph->set_x_axis_font($params{labelFont}, $params{labelFontSize}) or die $graph->error;
  $graph->set_y_axis_font($params{labelFont}, $params{labelFontSize}) or die $graph->error;
  # Plot the data, and add it to the GD object.
  my $plot = $graph->plot($params{data}) or die $graph->error;
  $gd->copy($plot, 0, $graphicTop, 0, 0, $params{width}, $params{height} - $titleSpace - $legendSpace);
  # Detect the format to save the image as.
  my $imageType = 'png';
  if ($params{fileName} =~ /.*\.(.*)$/) {
    if ($1 =~ /png/i) {
      $imageType = 'png';
    }
    elsif ($1 =~ /gif/i) {
      $imageType = 'gif';
    }
    elsif ($1 =~ /jpe?g/i) {
      $imageType = 'jpeg';
    }
  }
  # Make directory and write GD object to an image.
  createDirectory (fileName => $params{fileName});
  open(IMG, ">" . $params{fileName}) or die $!;
    binmode IMG;
    print IMG $gd->$imageType;
  close(IMG);
};

# Public Methods.

=head2 new

 Title   : new
 Usage   : private
 Function: Creates a new Pigeon::Graphics::GD object for use in the Pigeon::Graphics package.
 Returns : Pigeon::Graphics::GD object

=cut

sub new {
  my $invocant = shift;
  my %params = @_;
  my $class = ref ($invocant) || $invocant;
  my $self = {
  };
  bless $self => $class;
  return $self;
}

=head2 drawBarGraph

  Title    : drawBarGraph
  Usage    : private
  Function : Creates a bar graph of the provided data using GD::Graph
  Params   : data              - Arrary reference to GD::Graph formated data.
             legend            - Arrary reference to Legend.
             dataColors        - Array reference to Colors used to draw the data and legend.
             xAxisTitle        - Label for the X axis.
             xLabelSkip        - Skip every n labels on the X axis.
             yAxisTitle        - Label for the Y axis.
             yLabelSkip        - Skip evey n labels on the Y axis.
             maximumValue      - Maximum value for the Y axis.
             width             - Width of the image.
             height            - Height of the image.
             fileName          - File name to save image to.
             backgroundColor   - Color of the background.
             title             - Title of this image.
             titleAlignment    - Alignment of the title: left, center, right.
             titleFont         - Font to use for the title.
             titleFontSize     - Font size to use for the title.
             titleColor        - Color to draw the title.
             subTitle          - Sub-title of this image.
             subTitleAlignment - Alignment of the sub-title: left, center, right.
             subTitleFont      - Font to use for the sub-title.
             subTitleFontSize  - Font size to use for the sub-title.
             subtitleColor     - Color to draw the sub-title.
             labelFont         - Font to use for the labels.
             labelFontSize     - Font size to use for the labels.
             labelColor        - Color to draw the labels.
             legendType        - The type of legend to draw: classic, gradient.
             legendLocation    - Location to draw the legend: bottom, top, none.
             legendAlignment   - Alignment of the legend: left, center, right.
             legendFont        - Font to use for the legend.
             legendFontSize    - Font size to use for the legend.
             legendColor       - Color to draw the legend.
             legendTitle       - Titile of the legend.
             cumulate          - Cumulate the data: 0, 1.

=cut

sub drawBarGraph {
  my $self = shift;
  my %params = @_;
  $self->$drawGraph (type => 'bar', %params);
}

=head2 drawLineGraph

  Title    : drawLineGraph
  Usage    : private
  Function : Creates a line graph of the provided data using GD::Graph
  Params   : data              - Arrary reference to GD::Graph formated data.
             legend            - Arrary reference to Legend.
             dataColors        - Array reference to Colors used to draw the data and legend.
             xAxisTitle        - Label for the X axis.
             xLabelSkip        - Skip every n labels on the X axis.
             yAxisTitle        - Label for the Y axis.
             yLabelSkip        - Skip evey n labels on the Y axis.
             maximumValue      - Maximum value for the Y axis.
             width             - Width of the image.
             height            - Height of the image.
             fileName          - File name to save image to.
             backgroundColor   - Color of the background.
             title             - Title of this image.
             titleAlignment    - Alignment of the title: left, center, right.
             titleFont         - Font to use for the title.
             titleFontSize     - Font size to use for the title.
             titleColor        - Color to draw the title.
             subTitle          - Sub-title of this image.
             subTitleAlignment - Alignment of the sub-title: left, center, right.
             subTitleFont      - Font to use for the sub-title.
             subTitleFontSize  - Font size to use for the sub-title.
             subtitleColor     - Color to draw the sub-title.
             labelFont         - Font to use for the labels.
             labelFontSize     - Font size to use for the labels.
             labelColor        - Color to draw the labels.
             legendType        - The type of legend to draw: classic, gradient.
             legendLocation    - Location to draw the legend: bottom, top, none.
             legendAlignment   - Alignment of the legend: left, center, right.
             legendFont        - Font to use for the legend.
             legendFontSize    - Font size to use for the legend.
             legendColor       - Color to draw the legend.
             legendTitle       - Titile of the legend.

=cut

sub drawLineGraph {
  my $self = shift;
  my %params = @_;
  $self->$drawGraph (type => 'line', %params);
}

=head2 drawPointGraph

  Title    : drawPointGraph
  Usage    : private
  Function : Creates a point graph of the provided data using GD::Graph
  Params   : data              - Arrary reference to GD::Graph formated data.
             legend            - Arrary reference to Legend.
             dataColors        - Array reference to Colors used to draw the data and legend.
             xAxisTitle        - Label for the X axis.
             xLabelSkip        - Skip every n labels on the X axis.
             yAxisTitle        - Label for the Y axis.
             yLabelSkip        - Skip evey n labels on the Y axis.
             maximumValue     - Maximum value for the Y axis.
             width             - Width of the image.
             height            - Height of the image.
             fileName          - File name to save image to.
             backgroundColor   - Color of the background.
             title             - Title of this image.
             titleAlignment    - Alignment of the title: left, center, right.
             titleFont         - Font to use for the title.
             titleFontSize     - Font size to use for the title.
             titleColor        - Color to draw the title.
             subTitle          - Sub-title of this image.
             subTitleAlignment - Alignment of the sub-title: left, center, right.
             subTitleFont      - Font to use for the sub-title.
             subTitleFontSize  - Font size to use for the sub-title.
             subtitleColor     - Color to draw the sub-title.
             labelFont         - Font to use for the labels.
             labelFontSize     - Font size to use for the labels.
             labelColor        - Color to draw the labels.
             legendType        - The type of legend to draw: classic, gradient.
             legendLocation    - Location to draw the legend: bottom, top, none.
             legendAlignment   - Alignment of the legend: left, center, right.
             legendFont        - Font to use for the legend.
             legendFontSize    - Font size to use for the legend.
             legendColor       - Color to draw the legend.
             legendTitle       - Titile of the legend.

=cut

sub drawPointGraph {
  my $self = shift;
  my %params = @_;
  $self->$drawGraph (type => 'point', %params);
}

1;
__END__

=head1 NAME

  Pigeon::Graphics::Image - Image::Magick specific methods used in Pigeon::Graphics.

=head1 SYNOPSIS

  Private usage by Pigeon.

=head1 DESCRIPTION

  This package holds Image::Magick specific methods used in Pigeon::Graphics.

=head1 DEPENDENCIES

  This package depends on various packages in the Pigeon hierarchy,
  in addition to Image::Magick.

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

=cut

package Pigeon::Graphics::Image;

use strict;
use warnings;

use Pigeon::Tools qw(:all);
use Image::Magick;

use constant TEST_LINE => 'ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890abcdefghijklmnopqrstuvwxyz';

my $defaultPixelSize = 1;

## Private Methods.

my $rotate = sub {
  my $self = shift;
  my %params = @_;
  my $pi = 4 * atan2 (1, 1);
  my $sin = sin ($params{angle} * $pi / 180);
  my $cos = cos ($params{angle} * $pi / 180);
  my $x = $params{x} * $cos - $params{y} * $sin;
  my $y = $params{y} * $cos + $params{x} * $sin;
  return [$x, $y];
};

my $stringMetrics = sub {
  my $self = shift;
  my %params = @_;
  my $image = Image::Magick->new;
  $image->ReadImage('xc:transparent');
  my ($xPpem, $yPpem, $ascender, $descender, $textWidth, $textHeight, $maxAdvance) = $image->QueryFontMetrics (
    'text'      => $params{text},
    'font'      => $params{font},
    'pointsize' => $params{fontSize}
  );
  undef $image;
  # Add half the text height as a margin for the text width.
  $textWidth += ceil ($textHeight / 2);
  # Calculate the location of points a, b, and c after rotation. The origin (point o) does not move.
  #   a________________b
  #    |               |
  #    | RENDERED TEXT |
  #    |_______________|
  #   o                c
  #
  my $a = $self->$rotate (
    'x'     => 0,
    'y'     => $textHeight,
    'angle' => $params{rotate}
  );
  my $b = $self->$rotate (
    'x'     => $textWidth,
    'y'     => $textHeight,
    'angle' => $params{rotate}
  );
  my $c = $self->$rotate (
    'x'     => $textWidth,
    'y'     => 0,
    'angle' => $params{rotate}
  );
  # Calculate the width and height of the text after rotation.
  my $width = ceil (abs ($b->[0]));
  my $height = ceil (abs ($a->[1] - $c->[1]));  
  return ($width, $height);
};

my $annotate = sub {
  my $self = shift;
  my %params = @_;
  # Discover maximum dimensions of the text when rendered.
  my ($width, $height) = $self->$stringMetrics (
    text     => $params{text},
    rotate   => $params{rotate},
    font     => $params{font},
    fontSize => $params{fontSize}
  );
  # Create a new transparent image.
  my $image = Image::Magick->new (
    size => $width . 'x' . $height
  );
  $image->ReadImage('xc:transparent');
  # Annotate the image.
  $image->Annotate (
    'font'      => $params{font},
    'antialias' => 'true',
    'pointsize' => $params{fontSize},
    'fill'      => $params{color},
    'text'      => $params{text},
    'rotate'    => $params{rotate},
    'x'         => 0,
    'y'         => 0,
    'gravity'   => 'center'
  );
  return $image;
};

my $translate = sub {
  my $self = shift;
  my %params = @_;
  my $translation;
  my $dimension = $params{dimension} - (2 * $params{buffer});
  if (abs ($params{maximum} - $params{minimum}) > 0) {
    $translation = ($params{value} - $params{minimum}) * $dimension / abs ($params{maximum} - $params{minimum}) + $params{buffer};
    if ($params{invert} == 1) {
      $translation = $params{dimension} - $translation;
    }
  }
  return $translation;
};

my $drawLine = sub {
  my $self = shift;
  my %params = @_;
  my ($points, $primitive, $stroke, $fill);
  foreach my $point (@{$params{points}}) {
    $points .= $point->[0] . ',' . $point->[1] . ' ';
  }
  if (@{$params{points}} == 1) {
    my $x = $params{points}->[0]->[0] + round ($params{pixelSize} / 2);
    my $y = $params{points}->[0]->[1] + round ($params{pixelSize} / 2);
    $points .= $x . ',' . $y;
    $primitive = 'circle';
    $stroke = 'transparent';
    $fill = $params{color};
  }
  if (@{$params{points}} == 2) {
    $primitive = 'line';
    $stroke = $params{color};
    $fill = 'transparent';
  }
  if (@{$params{points}} > 2) {
    $primitive = 'polyline';
    $stroke = $params{color};
    $fill = 'transparent';
  }
  $params{image}->Draw (
    'primitive'   => $primitive,
    'fill'        => $fill,
    'stroke'      => $stroke,
    'strokewidth' => $params{pixelSize},
    'points'      => $points,
    'antialias'   => 'true'
  );
};

my $drawTitles = sub {
  my $self = shift;
  my %params = @_;
  my $titles = Image::Magick->new (
    size => $params{width} . 'x' . $params{height}
  );
  $titles->ReadImage('xc:transparent');
  my $height = 0;
  # Calculate space for, and draw titles.
  foreach my $title (@{$params{titles}}) {
    my ($xOffset, $yOffset);
    my ($stringWidth, $stringHeight) = $self->$stringMetrics (
      text     => $title,
      rotate   => 0,
      font     => $params{font},
      fontSize => $params{fontSize}
    );
    if ($params{alignment} eq 'center') {
      $xOffset = round (($params{width} - $stringWidth) / 2);
    }
    elsif ($params{alignment} eq 'right') {
      $xOffset = $params{width} - $stringWidth;
    }
    elsif ($params{alignment} eq 'left') {
      $xOffset = 0;
    }
    else {
      $xOffset = 0;
    }
    $yOffset = $height + $stringHeight;
    $titles->Annotate (
      'font'      => $params{font},
      'pointsize' => $params{fontSize},
      'fill'      => $params{fontColor},
      'text'      => $title,
      'x'         => $xOffset,
      'y'         => $yOffset
    );
    $height += $stringHeight + ceil ($stringHeight / 2);
  }
  return $titles;
};

my $drawLegend = sub {
  my $self = shift;
  my %params = @_;
  my $image = Image::Magick->new (
    size => $params{width} . 'x' . $params{height}
  );
  $image->ReadImage('xc:transparent');
  my ($width, $height);
  my $maxWidth = 0;
  my $maxHeight = 0;
  foreach my $legend (@{$params{legend}}) {
    ($width, $height) = $self->$stringMetrics (
        text     => $legend,
        rotate   => 0,
        font     => $params{font},
        fontSize => $params{fontSize}
    );
    if ($width > $maxWidth) {
      $maxWidth = $width;
    }
    if ($height > $maxHeight) {
      $maxHeight = $height;
    }
  }
  my $spacer = floor ($maxHeight / 2);
  my $cellWidth = $maxWidth + ($maxHeight * 2);
  # Calculate the height of the key.
  my $cellHeight;
  if (@{$params{legend}} > 0) {
    $cellHeight = $params{height} / ceil (@{$params{legend}} / $params{columns});
  }
  else {
    $cellHeight = 0;
  }
  # Draw key.
  my $leftOffset;
  if ($params{alignment} eq 'left') {
    $leftOffset = $spacer;
  }
  elsif ($params{alignment} eq 'right') {
    $leftOffset = $params{width} - $cellWidth * $params{columns}
  }
  elsif ($params{alignment} eq 'center') {
    $leftOffset = ($params{width} - $cellWidth * $params{columns}) / 2;
  }
  for (my $i = 0; $i < @{$params{legend}}; $i ++) {
    my $top = floor ($i / $params{columns}) * $cellHeight + $spacer;
    my $left = $leftOffset + ($i % $params{columns}) * $cellWidth + $spacer;
    $image->Annotate (
      'font'      => $params{font},
      'pointsize' => $params{fontSize},
      'fill'      => $params{fontColor},
      'text'      => $params{legend}->[$i],
      'x'         => $left + $spacer + $height,
      'y'         => $top + floor (0.9 * $height)
    );
    $image->Draw (
      'stroke'    => $params{color},
      'fill'      => $params{dataColors}->[$i % @{$params{dataColors}}],
      'primitive' => 'rectangle',
      'points'    => $left . ',' . $top . ' ' . ($left + $height) . ',' . ($top + $height)
    );
  }
  return $image;
};

my $drawLabel = sub {
  my $self = shift;
  my %params = @_;
  my ($width, $height, $rotation, $invert, $titleOffset, $labelOffset, $ticOffset);
  my $pixelSize = 3;
  # Create temporary Image::Magick object.
  my $temp = Image::Magick->new (
    size => $params{width} . 'x' . $params{height}
  );
  $temp->ReadImage('xc:transparent');
  my ($stringWidth, $stringHeight) = $self->$stringMetrics (
    text     => $params{title},
    rotate   => 0,
    font     => $params{font},
    fontSize => $params{fontSize}
  );
  if ($params{position} eq 'top') {
    $width = $params{width};
    $height = $params{height};
    $rotation = 0;
    $titleOffset = $stringHeight;
    $labelOffset = $height - $stringHeight;
    $ticOffset = $height - ceil ($pixelSize / 2);
  }
  elsif ($params{position} eq 'bottom') {
    $width = $params{width};
    $height = $params{height};
    $rotation = 0;
    $titleOffset = $height - ceil (0.5 * $stringHeight);
    $labelOffset = ceil (1.5 * $stringHeight);
    $ticOffset = floor ($pixelSize / 2);
  }
  elsif ($params{position} eq 'left') {
    $width = $params{height};
    $height = $params{width};
    $rotation = 270;
    $titleOffset = $stringHeight;
    $labelOffset = $height - ceil (0.5 * $stringHeight);
    $ticOffset = $height - ceil ($pixelSize / 2);
  }
  elsif ($params{position} eq 'right') {
    $width = $params{height};
    $height = $params{width};
    $rotation = 270;
    $titleOffset = $height - ceil (0.5 * $stringHeight);
    $labelOffset = $stringHeight;
    $ticOffset = floor ($pixelSize / 2);
  }
  # Create Image::Magick object.
  my $image = Image::Magick->new (
    size => $width . 'x' . $height
  );
  $image->ReadImage('xc:transparent');
  # Draw title.
  ($stringWidth, $stringHeight) = $self->$stringMetrics (
    text     => $params{title},
    rotate   => 0,
    font     => $params{font},
    fontSize => $params{fontSize}
  );
  $image->Annotate (
    'font'      => $params{font},
    'pointsize' => $params{fontSize},
    'fill'      => $params{fontColor},
    'text'      => $params{title},
    'x'         => ($width - $stringWidth) / 2,
    'y'         => $titleOffset,
    'rotate'    => 0
  );
  # Draw labels.
  for (my $i = 0; $i < @{$params{labels}}; $i ++) {
    # Create the label.
    my $label = $self->$annotate (
      'text'     => $params{labels}->[$i],
      'color'    => $params{fontColor},
      'rotate'   => $params{labelRotation},
      'font'     => $params{font},
      'fontSize' => $params{fontSize},
    );
    my $labelWidth = $label->Get('width');
    my $loc;
    # If there are less labels than label locations, it assumed that the labels
    # are drawn in the center of the tics, rather than below them.
    if (@{$params{labels}} < @{$params{labelLocation}}) {
      # Draw labels between the tics.
      $loc = $self->$translate (
        value     => round (($params{labelLocation}->[$i] + $params{labelLocation}->[$i + 1]) / 2),
        minimum   => $params{minimum},
        maximum   => $params{maximum},
        dimension => $width,
        invert    => 0,
        buffer    => $pixelSize
      );
      $loc -= round ($labelWidth / 2);
    }
    else {
      # Draw labels below the tics.
      $loc = $self->$translate (
        value     => $params{labelLocation}->[$i],
        minimum   => $params{minimum},
        maximum   => $params{maximum},
        dimension => $width,
        invert    => 0,
        buffer    => $pixelSize
      );
      $loc -= round ($labelWidth / 2);
    }
    # Make sure the label doesn't get cut off.
    if ($loc < 0) {
      $loc = 0;
    }
    if ($loc > $width - $labelWidth) {
      $loc = $width - $labelWidth;
    }
    # Add the label to image.
    $image->Composite (
      'image' => $label,
      'x'     => $loc,
      'y'     => $labelOffset - $label->Get('height')
    );
  }
  # Draw edge and tic marks.
  my $axisMinimum = $self->$translate (
    value     => $params{minimum},
    minimum   => $params{minimum},
    maximum   => $params{maximum},
    dimension => $width,
    invert    => 0,
    buffer    => $pixelSize
  );
  my $axisMax = $self->$translate (
    value     => $params{maximum},
    minimum   => $params{minimum},
    maximum   => $params{maximum},
    dimension => $width,
    invert    => 0,
    buffer    => $pixelSize
  );
  $self->$drawLine (
    image     => $image,
    points    => [[$axisMinimum, $ticOffset], [$axisMax, $ticOffset]],
    color     => $params{color},
    pixelSize => $pixelSize
  );
  foreach my $tic (@{$params{labelLocation}}) {
    my $loc = $self->$translate (
      value     => $tic,
      minimum   => $params{minimum},
      maximum   => $params{maximum},
      dimension => $width,
      invert    => 0,
      buffer    => $pixelSize
    );
    $self->$drawLine (
      image     => $image,
      points    => [[$loc, abs ($ticOffset - floor ($stringHeight / 2))], [$loc, $ticOffset]],
      color     => $params{color},
      pixelSize => $pixelSize
    );
  }
  # Rotate image
  $image->Rotate (
    degrees => $rotation
  );
  return $image;
};

my $drawLongTics = sub {
  my $self = shift;
  my %params = @_;
  my $image = Image::Magick->new (
    size => $params{width} . 'x' . $params{height}
  );
  $image->ReadImage('xc:transparent');
  my $pixelSize = 1;
  # Grab the minimum and maximum X values.
  my $xMinimum = $self->$translate (
    value     => $params{xMinimumValue},
    minimum   => $params{xMinimumValue},
    maximum   => $params{xMaximumValue},
    dimension => $params{width},
    invert    => 0,
    buffer    => $pixelSize
  );
  my $xMaximum = $self->$translate (
    value     => $params{xMaximumValue},
    minimum   => $params{xMinimumValue},
    maximum   => $params{xMaximumValue},
    dimension => $params{width},
    invert    => 0,
    buffer    => $pixelSize
  );
  # Grab the minimum and maximum Y values.
  my $yMinimum = $self->$translate (
    value     => $params{yMinimumValue},
    minimum   => $params{yMinimumValue},
    maximum   => $params{yMaximumValue},
    dimension => $params{height},
    invert    => 1,
    buffer    => $pixelSize
  );
  my $yMaximum = $self->$translate (
    value     => $params{yMaximumValue},
    minimum   => $params{yMinimumValue},
    maximum   => $params{yMaximumValue},
    dimension => $params{height},
    invert    => 1,
    buffer    => $pixelSize
  );
  # Draw the tics along the X axis.
  if ($params{xAxisLongTics}) {
    foreach my $tic (@{$params{xAxisTicLocation}}) {
      if ($tic != $params{xMinimumValue}) {
        my $loc = $self->$translate (
          value     => $tic,
          minimum   => $params{xMinimumValue},
          maximum   => $params{xMaximumValue},
          dimension => $params{width},
          invert    => 0,
          buffer    => $pixelSize
        );
        $self->$drawLine (
          image     => $image,
          points    => [[$loc, $yMinimum], [$loc, $yMaximum]],
          color     => $params{color},
          pixelSize => $pixelSize
        );
      }
    }
  }
  # Draw the tics along the Y axis.
  if ($params{yAxisLongTics}) {
    foreach my $tic (@{$params{yAxisTicLocation}}) {
      if ($tic != $params{yMinimum}) {
        my $loc = $self->$translate (
          value     => $tic,
          minimum   => $params{yMinimumValue},
          maximum   => $params{yMaximumValue},
          dimension => $params{height},
          invert    => 1,
          buffer    => $pixelSize
        );
        $self->$drawLine (
          image     => $image,
          points    => [[$xMinimum, $loc], [$xMaximum, $loc]],
          color     => $params{color},
          pixelSize => $pixelSize
        );
      }
    }
  }
  return $image;
};

my $drawData = sub {
  my $self = shift;
  my %params = @_;
  my $data = Image::Magick->new (
    size => $params{width} . 'x' . $params{height}
  );
  $data->ReadImage('xc:transparent');
  for (my $i = 0; $i < @{$params{data}}; $i ++) {
    my $index = $i % @{$params{pixelSize}};
    foreach my $line (@{$params{data}->[$i]}) {
      my @points;
      foreach my $point (@{$line}) {
        my $x = $self->$translate (
          value     => $point->[0],
          minimum   => $params{xMinimumValue},
          maximum   => $params{xMaximumValue},
          dimension => $params{width},
          invert    => 0,
          buffer    => $params{pixelSize}->[$index]
        );
        my $y = $self->$translate (
          value     => $point->[1],
          minimum   => $params{yMinimumValue},
          maximum   => $params{yMaximumValue},
          dimension => $params{height},
          invert    => 1,
          buffer    => $params{pixelSize}->[$index]
        );
        push (@points, [$x, $y]);
      }
      # Make sure that a line with only two points is at least the length of pixelSize.
      if (@points == 2 && (distance ($points[0], $points[1]) < $params{pixelSize}->[$index])) {
        $points[1][0] += $params{pixelSize}->[$index];
      }
      $self->$drawLine (
        points    => \@points,
        color     => $params{dataColors}->[$index],
        pixelSize => $params{pixelSize}->[$index],
        image     => $data
      );
    }
  }
  return $data;
};

my $saveImage = sub {
  my $self = shift;
  my %params = @_;
  # Create directory structure.
  createDirectory (fileName => $params{fileName});
  # Create image
  $params{image}->Write (filename => $params{fileName});
};

## Public Methods.

=head2 new

 Title   : new
 Usage   : private
 Function: Creates a new Pigeon::Graphics::Image object for use in the Pigeon::Graphics package.
 Returns : Pigeon::Graphics::Image object

=cut

sub new {
  my $invocant = shift;
  my %params = @_;
  my $class = ref ($invocant) || $invocant;
  my $self = {};
  bless $self => $class;
  return $self;
}

=head2 plot

  Title    : plot
  Usage    : private

             # Format of the data argument:
             # 
             # data is an array of data sets, with each data set requiring its own color defined
             # in the colors argument.  Each data set is composed of multi-segment lines, with each
             # line segment being an array of points in a [x, y] space.

             # Single point
             my $set1 = [
               [[1, 1]]
             ];
             # Line
             my $set2 = [
               [[5, 5],[5, 10]]
             ];
             # Multiple lines
             my $set3 = [
                [[15, 15], [15, 20]],
                [[25, 15], [25, 20], [20, 20]],
                [[50, 50], [100, 100], [150, 50], [50, 50]]
             ];
             # Build the data array from the data sets.
             my $data = [
               $set1,
               $set2,
               $set3,
             ];
             # The number of dataColors must be the same as the number of data sets.           
             my $colors = [
               'red',
               'blue',
               'green',
             ];

  Function : Plots the provided data, saving it in the provided file name.
  Args     : fileName           - File name to save the plot to.
             data               - Array reference to the data to draw.
             dataColors         - Array reference to the colors used to draw the data.
             width              - Width of the image.
             height             - Height of the image.
             title              - Title of this image.
             titleAlignment     - Alignment of the title, left, right, or default center.
             titleFont          - Font to use for the title.
             titleFontSize      - Font size to use for the title.
             titleColor         - Color to draw the title.
             subTitle           - Sub-title of this image.
             subTitleAlignment  - Alignment of the sub-title, left, right, or default center.
             subTitleFont       - Font to use for the title.
             subTitleFontSize   - Font size to use for the sub-title.
             subTitleColor      - Color to draw the sub-title.
             legend             - Array reference to the legend to display.
             legendLocation     - Location to draw the legend: top, bottom, or none.
             legendAlignment    - Alignment of the legend: left, center, right.
             labelColor         - Color to draw labels.
             color              - Color to draw graph objects, default black.
             normalFont         - Font to use for the the labels.
             normalFontSize     - Font size to use for the labels.
             normalFontColor    - Color to draw the labels.
             pixelSize          - Array reference to the pixel size use to draw the data.
             xMinimumValue      - Minimum x value.
             xMaximumValue      - Maximum x value.
             xAxisTitle         - Title of the x axis.
             xAxisLocation      - Location to draw the x axis.
             xAxisLabels        - Array reference containing the labels to draw for the tics on the x axis.
             xAxisLabelLocation - Array reference containing the location to draw tics on the x axis.
             xAxisLabelRotation - The degrees to rotate the text label along the x axis.
             xAxisLongTics      - Display long tics on the x axis, 0 disable, 1 enable, default 0.
             yMinimumValue      - Minimum y value.
             yMaximumValue      - Maximum y value.
             yAxisTitle         - Title of the y axis.
             yAxisLocation      - Location to draw the y labels.
             yAxisLabels        - Array reference containing the labels to draw for the tics on the y axis.
             yAxisLabelLocation - Array reference containing the location to draw tics on the y axis.
             yAxisLabelRotation - The degrees to rotate the text label along the y axis.
             yAxisLongTics      - Display long tics on the y axis, 0 disable, 1 enable, default 0.

=cut

sub plot {
  my $self = shift;
  my %params = @_;
  # Define the default values for each section of the graphic.
  my $title = {
    'x'      => 0,
    'y'      => 0,
    'width'  => 0,
    'height' => 0
  };
  my $legend = {
    'x'      => 0,
    'y'      => 0,
    'width'  => 0,
    'height' => 0
  };
  my $xAxis = {
    'x'      => 0,
    'y'      => 0,
    'width'  => 0,
    'height' => 0
  };
  my $yAxis = {
    'x'      => 0,
    'y'      => 0,
    'width'  => 0,
    'height' => 0
  };
  my $plot = {
    'x'      => 0,
    'y'      => 0,
    'width'  => 0,
    'height' => 0
  };
  # Create the image.
  my $image = Image::Magick->new (
    size => $params{width} . 'x' . $params{height}
  );
  $image->ReadImage('xc:white');
  # Calculate string space
  my ($width, $height);
  ($width, $height) = $self->$stringMetrics (
    text     => TEST_LINE,
    rotate   => 0,
    font     => $params{titleFont},
    fontSize => $params{titleFontSize}
  );
  my $titleStringSpace = ceil ($height * 1.5); 
  ($width, $height) = $self->$stringMetrics (
    text     => TEST_LINE,
    rotate   => 0,
    font     => $params{normalFont},
    fontSize => $params{normalFontSize}
  );
  my $spacer = ceil ($height / 2);
  my $stringSpace = $height + $spacer; 
  # Calculate the number of columns to use when drawing the legend.
  my $legendColumns = 1;
  if (defined $params{legend}) {
    my $maxWidth = 0;
    foreach my $legend (@{$params{legend}}) {
      my ($stringWidth) = $self->$stringMetrics (
        text     => $legend,
        rotate   => 0,
        font     => $params{normalFont},
        fontSize => $params{normalFontSize}
      );
      if ($stringWidth > $maxWidth) {
        $maxWidth = $stringWidth;
      }
    }
    if ($maxWidth > 0) {
      # columns is equal to the width of the image / (maximum width of the legends + room for the colored box + spacer)
      $legendColumns = floor ($params{width} / ($maxWidth + $stringSpace + $spacer));
      if ($legendColumns > @{$params{legend}}) {
        $legendColumns = @{$params{legend}};
      }
    }
  }
  # Calculate the dimensions of various components.
  if (defined $params{titles}) {
    $title->{height} = $titleStringSpace * @{$params{titles}};
    $title->{width} = $params{width};
  }
  if (defined $params{legend} && $params{legendLocation} ne 'none') {
    $legend->{height} = $stringSpace * ceil(@{$params{legend}} / $legendColumns);
    $legend->{width} = $params{width};
  }
  if (defined $params{xAxisLabels}) {
    my $max = 0;
    foreach my $label (@{$params{xAxisLabels}}) {
      ($width, $height) = $self->$stringMetrics (
        text     => $label,
        rotate   => $params{xAxisLabelRotation},
        font     => $params{normalFont},
        fontSize => $params{normalFontSize},
      );
      if ($height > $max) {
        $max = $height;
      }
    }
    $xAxis->{height} = $max + floor (1.5 * $stringSpace);
  }
  else {
    $xAxis->{height} = 2 * $stringSpace;
  }
  if (defined $params{yAxisLabels}) {
    my $max = 0;       
    foreach my $label (@{$params{yAxisLabels}}) {
      ($width, $height) = $self->$stringMetrics (
        text     => $label,
        rotate   => $params{yAxisLabelRotation} + 270,
        font     => $params{normalFont},
        fontSize => $params{normalFontSize},
      );
      if ($width > $max) {
        $max = $width;
      }
    }
    $yAxis->{width} = $max + floor (1.5 * $stringSpace);
  }
  else {
    $yAxis->{width} = 2 * $stringSpace;
  }
  $xAxis->{width} = $params{width} - $yAxis->{width};
  $yAxis->{height} = $params{height} - $title->{height} - $legend->{height} - $xAxis->{height};
  $plot->{width} = $xAxis->{width};
  $plot->{height} = $yAxis->{height};
  # Calculate the location to draw various components.
  my $topOffset = $title->{height};
  if (defined $params{legend} && defined $params{legendLocation} && $params{legendLocation} eq 'top') {
    $legend->{y} = $title->{height};
    $topOffset += $legend->{height};
  }
  elsif (defined $params{legend} && defined $params{legendLocation} && $params{legendLocation} eq 'bottom') {
    $legend->{y} = $params{height} - $legend->{height};
  }
  if (defined $params{xAxisLocation} && $params{xAxisLocation} eq 'top') {
    $xAxis->{y} = $topOffset;
    $yAxis->{y} = $topOffset + $xAxis->{height};
    $plot->{y} = $topOffset + $xAxis->{height};
  }
  elsif (defined $params{xAxisLocation} && $params{xAxisLocation} eq 'bottom') {
    $xAxis->{y} = $topOffset + $yAxis->{height};
    $yAxis->{y} = $topOffset;
    $plot->{y} = $topOffset;
  }
  if (defined $params{yAxisLocation} && $params{yAxisLocation} eq 'left') {
    $xAxis->{x} = $yAxis->{width};
    $plot->{x} = $yAxis->{width};
  }
  elsif (defined $params{yAxisLocation} && $params{yAxisLocation} eq 'right') {
    $yAxis->{x} = $xAxis->{width};
  }
  # Draw the titles.
  if (defined $params{titles}) {
    my $titleImage = $self->$drawTitles (
      titles    => $params{titles},
      alignment => $params{titleAlignment},
      font      => $params{titleFont},
      fontSize  => $params{titleFontSize},
      fontColor => $params{titleColor},
      width     => $title->{width},
      height    => $title->{height}
    );
    $image->Composite (
      'image' => $titleImage,
      'x'     => $title->{x},
      'y'     => $title->{y},
    );
  }
  # Draw the legend.
  if (defined $params{legend} && $params{legendLocation} ne 'none') {
    my $legendImage = $self->$drawLegend (
      legend     => $params{legend},
      dataColors => $params{dataColors},
      color      => $params{color},
      alignment  => $params{legendAlignment},
      columns    => $legendColumns,
      font       => $params{normalFont},
      fontSize   => $params{normalFontSize},
      fontColor  => $params{normalFontColor},
      width      => $legend->{width},
      height     => $legend->{height}
    );
    $image->Composite (
      'image' => $legendImage,
      'x'     => $legend->{x},
      'y'     => $legend->{y}
    );
  }
  # Draw the X axis labels.
  my $xAxisLabel = $self->$drawLabel (
    position      => $params{xAxisLocation},
    minimum       => $params{xMinimumValue},
    maximum       => $params{xMaximumValue},
    title         => $params{xAxisTitle},
    labels        => $params{xAxisLabels},
    labelLocation => $params{xAxisLabelLocation},
    labelRotation => $params{xAxisLabelRotation},
    font          => $params{normalFont},
    fontSize      => $params{normalFontSize},
    fontColor     => $params{normalFontColor},
    color         => $params{color},
    width         => $xAxis->{width},
    height        => $xAxis->{height}
  );
  $image->Composite (
    'image' => $xAxisLabel,
    'x'     => $xAxis->{x},
    'y'     => $xAxis->{y}
  );
  # Draw the Y axis labels.
  my $yAxisLabel = $self->$drawLabel (
    position      => $params{yAxisLocation},
    minimum       => $params{yMinimumValue},
    maximum       => $params{yMaximumValue},
    title         => $params{yAxisTitle},
    labels        => $params{yAxisLabels},
    labelLocation => $params{yAxisLabelLocation},
    labelRotation => $params{yAxisLabelRotation},
    font          => $params{normalFont},
    fontSize      => $params{normalFontSize},
    fontColor     => $params{normalFontColor},
    color         => $params{color},
    width         => $yAxis->{width},
    height        => $yAxis->{height}
  );
  $image->Composite (
    'image' => $yAxisLabel,
    'x'     => $yAxis->{x},
    'y'     => $yAxis->{y}
  );
  # Draw the long tics.
  my $longTics = $self->$drawLongTics (
    xMinimumValue    => $params{xMinimumValue},
    xMaximumValue    => $params{xMaximumValue},
    xAxisLongTics    => $params{xAxisLongTics},
    xAxisTicLocation => $params{xAxisLabelLocation},
    yMinimumValue    => $params{yMinimumValue},
    yMaximumValue    => $params{yMaximumValue},
    yAxisLongTics    => $params{yAxisLongTics},
    yAxisTicLocation => $params{yAxisLabelLocation},
    color            => $params{color},
    width            => $plot->{width},
    height           => $plot->{height}
  );
  $image->Composite (
    'image' => $longTics,
    'x'     => $plot->{x},
    'y'     => $plot->{y}
  );
  # Draw the data.
  if (defined $params{data}) {
    if (not defined $params{pixelSize}) {
      foreach (@{$params{data}}) {
        push @{$params{pixelSize}}, $defaultPixelSize;
      }
    }
    my $dataImage = $self->$drawData (
      xMinimumValue => $params{xMinimumValue},
      xMaximumValue => $params{xMaximumValue},
      yMinimumValue => $params{yMinimumValue},
      yMaximumValue => $params{yMaximumValue},
      data          => $params{data},
      dataColors    => $params{dataColors},
      width         => $plot->{width},
      height        => $plot->{height},
      pixelSize     => $params{pixelSize}
    );
    $image->Composite (
      'image' => $dataImage,
      'x'     => $plot->{'x'},
      'y'     => $plot->{'y'}
    );
  }
  # Save the image.
  $self->$saveImage (
    image    => $image,
    fileName => $params{fileName}
  );
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
  my ($r, $g, $b, $a) = @_;
  if (not defined $a) {
    $a = 1;
  }
  return "rgba($r, $g, $b, $a)";
}

1;
__END__

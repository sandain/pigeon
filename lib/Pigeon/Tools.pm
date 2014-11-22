=head1 NAME

  Pigeon::Tools

=head1 SYNOPSIS

  Private usage by Pigeon.

=head1 DESCRIPTION

  This package holds Tools used in various modules of the Pigeon package.

=head1 DEPENDENCIES

  This package depends on IO::Uncompress::AnyUncompress.

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

package Pigeon::Tools;

use strict;
use warnings;

use Bio::Seq;
use IO::Uncompress::AnyUncompress qw (anyuncompress $AnyUncompressError);

require Exporter;

our @ISA = qw (Exporter);

our %EXPORT_TAGS = (
  'all' => [ 
    qw (
      distance
      random
      ceil
      floor
      round
      createDirectory
      contains
      indexof
      check_parameters
      loadFile
      unzip
      sign
      test_categories
      nucleotide_is_equal
      translate
      sort_by_location
    )
  ]
);

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw ();

# Set default font and colors to use
my @default_colors = ('green', 'purple', 'red', 'blue', 'lbrown', 'dbrown', 'brown', 'lpurple', 'dpurple', 'orange', 'lblue', 'dblue');
my $default_font = '/usr/share/fonts/truetype/ttf-bitstream-vera/Vera.ttf';
my $default_bold_font = '/usr/share/fonts/truetype/ttf-bitstream-vera/VeraBd.ttf';
my $default_font_size = 15;
my $default_bold_font_size = 20;

=head2 distance

  Title    : distance
  Usage    : my $distance = distance (
               [0,  0, 0], # Point A
               [0, 10, 0]  # Point B
             );            # $distance = 10
  Function : Returns the Euclidean distance between the two given n dimensional points.
  Returns  : The Euclidean distance between the two given n dimensional points
  Args     : a - Array reference to the n dimensional point A
             b - Array reference to the n dimensional point B

=cut

sub distance {
  my ($a, $b) = @_;
  my $total = 0;
  my $dimensions;
  if (@{$a} < @{$b}) {
    $dimensions = @{$a};
  }
  else {
    $dimensions = @{$b};
  }
  for (my $n = 0; $n < $dimensions; $n ++) {
    $total += (($a->[$n] - $b->[$n]) ** 2);
  }
  return sqrt ($total);
}

=head2 random

  Title    : random
  Usage    :
  Function : Returns a pseudo-random number between the low and high value supplied.
  Returns  : Pseudo-random number between low and high.
  Args     : low: Lowest value to return
             high: Highest value to return

=cut

sub random {
  my %params = @_;
  my $num;
  if (defined $params{low} && defined $params{high}) {
    if ($params{low} == $params{high}) {
      $num = $params{low};
    }
    else {
      do {
        $num = rand($params{high} - $params{low}) + $params{low};
      }
      while ($num < $params{low} || $num > $params{high});
    }
    return $num;
  }
}

=head2 ceil

  Title    : ceil
  Usage    : $int = ceil (42.25);
  Function : Returns the provided real rounded up to the nearest integer.
  Returns  : Integer
  Args     : Real to ceiling

=cut

sub ceil {
  my $number = shift;
  return int ($number + 0.99);
}

=head2 floor

  Title    : floor
  Usage    : $int = floor (42.25);
  Function : Returns the provided real rounded down to the nearest integer.
  Returns  : Integer
  Args     : Real to floor

=cut

sub floor {
  my $number = shift;
  return int ($number);
}

=head2 round

  Title    : round
  Usage    : $int = round (42.25);
  Function : Returns the provided real rounded to the nearest integer.
  Returns  : Integer
  Args     : Real to round

=cut

sub round {
  my $number = shift;
  return int ($number + .5 * ($number <=> 0));
}

=head2 createDirectory

  Title    : createDirectory
  Usage    : createDirectory (fileName => '/home/user/test/test.txt');
             createDirectory (directory => '/home/user/test');
  Function : Creates the given directory structure.
  Returns  : The directory structure created.
  Args     : directory: Directory to create
             fileName: Fully qualified file name to create a directory structure for

=cut

sub createDirectory {
  my %params = @_;
  my @dirs;
  my $dirs = '';
  if (defined $params{fileName}) {
    $params{directory} = $params{fileName};
    $params{directory} =~ s/(.*)\/.*/$1/s;
    undef $params{directory} if ($params{directory} eq $params{fileName});
  }
  if (defined $params{directory}) {
    @dirs = split("/", $params{directory});
    foreach my $dir (@dirs) {
      $dirs = $dirs . $dir . '/';
      mkdir($dirs);
    }
  }
  return $dirs;
}

=head2 contains

  Title    : contains
  Usage    :
  Function : Tests whether the given list contains the item
  Returns  : 1 if the list contains the item, 0 if not, -1 if there is an error.
  Args     : item: Item to search for
             list: Array reference of list to search

=cut

sub contains {
  my %params = @_;
  my %list;
  if (defined $params{item} && defined $params{list}) {
    for (my $i = 0; $i < @{$params{list}}; $i ++) {
      $list{${$params{list}}[$i]} = 1;
    }
    if (defined $list{$params{item}}) {
      return 1;
    }
    else {
      return 0;
    }
  }
  else {
    return -1;
  }
}

=head2 indexof

  Title    : indexof
  Usage    :
  Function : Searches the array for the provided value, and returns its index.
  Returns  : The index of the first value found.
  Args     : value: Value to search array for
             array: Array to search

=cut

sub indexof {
  my %params = @_;
  my $index;
  if (defined $params{value} && defined $params{array}) {
    for (my $i = 0; $i < @{$params{array}}; $i++) {
      if ($params{array}[$i] eq $params{value}) {
        $index = $i;
      }
    }
  }
  return $index;
}

=head2 check_parameters

  Title    : check_parameters
  Usage    :
  Function : Returns default parameters for those not provided
  Returns  : Hash containing parameters
  Args     : params: Parameters to check
             defaults: Hash reference of default parameters

    Parameter Defaults
      file_name        => 'file_name'
      title            => 'Title'
      title_justify    => 'center'
      title_font       => $default_bold_font
      title_font_size  => $default_bold_font_size
      normal_font      => $default_font
      normal_font_size => $default_font_size
      colors           => \@default_colors
      bins             => ['total']
      metagenomes      => ['total']
      sizes            => ['total']
      extracted        => ['total']
      layers           => ['total']
      low              => 0
      high             => 100
      lows             => [0]
      highs            => [100]

=cut

sub check_parameters {
  my %args = @_;
  my %params;
  my %graphics = (
    file_name        => 'file_name.gif',
    title_justify    => 'center',
    legend_location  => 'bottom',
    legend_justify   => 'center',
    x_location       => 'bottom',
    y_location       => 'left',
    x_long_tics      => 0,
    y_long_tics      => 0,
    x_label_rotation => 0,
    y_label_rotation => 90,
    title_font       => $default_bold_font,
    title_font_size  => $default_bold_font_size,
    normal_font      => $default_font,
    normal_font_size => $default_font_size,
    colors           => \@default_colors
  );
  my %text = (
    file_name        => 'file_name.txt'
  );
  my %defaults = (
    low              => 0,
    high             => 100,
    bins             => ['total'],
    metagenomes      => ['total'],
    sizes            => ['total'],
    extracted        => ['total'],
    layers           => ['total']
  );
  # Load in user parameters.
  if (defined $args{params}) {
    %params = @{$args{params}};
  }
  # Make sure that type is defined.
  if (not defined $args{type}) {
    $args{type} = 'null';
  }
  # Check calling method provided defaults for missing parameters.
  foreach my $p (keys %{$args{defaults}}) {
    if (not defined $params{$p}) {
      $params{$p} = $args{defaults}{$p};
    }
  }
  # Fill any missing parameters.
  foreach my $p (keys %defaults) {
    if (not defined $params{$p}) {
      $params{$p} = $defaults{$p};
    }
  }
  if (lc $args{type} eq 'graphics') {
    foreach my $p (keys %graphics) {
      if (not defined $params{$p}) {
        $params{$p} = $graphics{$p};
      }
    }
  }
  elsif (lc $args{type} eq 'text') {
    foreach my $p (keys %text) {
      if (not defined $params{$p}) {
        $params{$p} = $text{$p};
      }
    }
  }
  # Fill lows and highs arrays
  for (my $i = 0; $i < @{$params{bins}}; $i ++) {
    if (not defined $params{lows}[$i]) {
      $params{lows}[$i] = $params{low};
    }
    if (not defined $params{highs}[$i]) {
      $params{highs}[$i] = $params{high};
    }
  }
  return %params;
}

=head2 loadFile

  Title    : loadFile
  Usage    : my $fh = loadFile ('filename');
  Function : Returns a file handle to the provided file, decompressing the file if necessary.
  Returns  : A file handle.
  Args     : A fully qualified file name to load.

=cut

sub loadFile {
  my ($file_name) = @_;
  my $fh;
  if (defined $file_name && -e $file_name) {
    if ($file_name =~ /.(bz2|gz|zip)$/i) {
      $fh = unzip ($file_name);
    }
    else {
      $fh = Symbol::gensym();
      open ($fh, $file_name) or die "Can't open file " . $file_name . ": " . $! . "\n";
    }
  }
  return $fh;
}

=head2 unzip

  Title    : unzip
  Usage    : $fh = unzip ('filename.gz');
  Function : Returns a file handle to the uncompressed file.
  Returns  : A file handle pointing to the uncompressed file.
  Args     : Fully qualified file name to unzip.

=cut

sub unzip {
  my ($file_name) = @_;
  my $fh;
  if (defined $file_name && -e $file_name) {
    $fh = new IO::Uncompress::AnyUncompress $file_name or die "unzip failed on " . $file_name . ": ". $AnyUncompressError . "\n";
  }
  return $fh;
}

=head2 sign

  Title    : sign
  Usage    : $x = (1, -1);
  Function : Returns the absolute value of $x and the sign of $y.
  Returns  : The absolute value of $x and the sign of $y.
  Args     : x: The value to return
             y: The sign to return
=cut

sub sign {
  my ($x, $y) = @_;
  my $result = abs($x);
  if ($y < 0.0) {
    $result = -$result;
  }
  return $result;
}

=head2 test_categories

  Title    : test_categories
  Usage    : 
  Function : Tests the categories
  Returns  : True or False
  Args     : item: Item to test against the list
             list: Array reference to the list of categories

=cut

sub test_categories {
  my %params = @_;
  if ( contains (%params) || contains (item => 'total', list => $params{list}) ||
       (contains (item => 'paired', list => $params{list}) && $params{item} =~ /^paired/) ||
       (contains (item => 'paired_syntenous', list => $params{list}) && $params{item} eq 'paired_good_good') ||
       (contains (item => 'paired_nonsyntenous', list => $params{list}) && (
         $params{item} eq 'paired_overlap' ||
         $params{item} eq 'paired_good_short' ||
         $params{item} eq 'paired_good_long' ||
         $params{item} =~ /^paired_outie/ ||
         $params{item} =~ /^paired_antinormal/ ||
         $params{item} =~ /^paired_normal/
       ))
     ) {
    return 1;
  }
  else {
    return 0;
  }
}

=head2 nucleotide_is_equal

  Title    : nucleotide_is_equal
  Usage    : nucleotide_is_equal ('a', 't');
  Function : Tests whether the two given nucleotides are equal, taking into account
             that either nucleotide could be ambiguous.
  Returns  : True or False
  Args     : The two nucleotides to test.

=cut

sub nucleotide_is_equal {
  my ($a, $b) = @_;
  # Define the nucleotide translation table.
  my $nucleotides = {
    'a' => ['a'],
    'c' => ['c'],
    'g' => ['g'],
    't' => ['t'],
    'r' => ['a', 'g'],
    'y' => ['c', 't'],
    'w' => ['a', 't'],
    's' => ['c', 'g'],
    'm' => ['a', 'c'],
    'k' => ['g', 't'],
    'b' => ['c', 'g', 't'],
    'd' => ['a', 'g', 't'],
    'h' => ['a', 'c', 't'],
    'v' => ['a', 'c', 'g'],
    'n' => ['a', 'c', 'g', 't']
  };
  # Check each possible combination of ambiguous nucleotides.
  my $equal = 0;
  foreach my $nuc_a (@{$nucleotides->{$a}}) {
    foreach my $nuc_b(@{$nucleotides->{$b}}) {
      if ($nuc_a eq $nuc_b) {
        $equal = 1;
      }
    }
  } 
  return $equal;
}

=head2 translate

  Title    : translate
  Usage    : my $translation = translate ('atccctgaa');
  Function : Translates a piece of DNA into its corresponding RNA.
  Return   : The translated RNA.
  Args     : Sequence - The DNA sequence to translate.

=cut

sub translate {
  my $sequence = shift;
  my $seq = new Bio::Seq (-seq => $sequence);
  my $translation = $seq->translate (@_);
  return $translation->seq ();
}

=head2 sort_by_location

  Title    : sort_by_location
  Usage    : foreach my $key (sort_by_location %reads) {
               print $key . "\n";
             }
  Function : Sorts the given reads hash, returning an array of keys sorted by location.
  Return   : An array of keys sorted by location.
  Args     : The reads hash to sort.

=cut

sub sort_by_location {
  my %reads = @_;
  my @keys = sort {
    my ($n, $m);
    # Grab the correct value to sort with from the first read.
    if (defined $reads{$a}{clone_pair} && defined $reads{$reads{$a}{clone_pair}}) {
      if ($reads{$a}{subject_start} < $reads{$reads{$a}{clone_pair}}{subject_start}) {
        $n = $reads{$a}{subject_start};
      }
      else {
        $n = $reads{$reads{$a}{clone_pair}}{subject_start};
      }
    }
    else {
      $n = $reads{$a}{subject_start};
    }
    # Grab the correct value to sort with from the second read.
    if (defined $reads{$b}{clone_pair} && defined $reads{$reads{$b}{clone_pair}}) {
      if ($reads{$b}{subject_start} < $reads{$reads{$b}{clone_pair}}{subject_start}) {
        $m = $reads{$b}{subject_start};
      }
      else {
        $m = $reads{$reads{$b}{clone_pair}}{subject_start};
      }
    }
    else {
      $m = $reads{$b}{subject_start};
    }
    # Sort.
    $n <=> $m;
  } keys %reads;
  return @keys;
}

1;
__END__


=head1 NAME

  Pigeon::Data::PCA

=head1 SYNOPSIS

  Private usage by Pigeon.

=head1 DESCRIPTION

  This package creates a Pigeon::Data::PCA object to handle the
  output of a R Principal Component Analysis.

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

package Pigeon::Data::PCA;

use strict;
use warnings;

my $int_max = 100000;
my $int_min = -100000;

=head2 new

  Title    : new
  Usage    : private
  Function : Creates a new Pigeon::Data::PCA object
  Returns  : New Pigeon::Data::PCA object
  Args     : name {name of this PCA}
             file_name {File name of PCA data to load}
             dimensions {Number of dimensions to import}

=cut

sub new {
  my $invocant = shift;
  my %params = @_;
  my $class = ref($invocant) || $invocant;
  my $self = {
    name                   => undef,
    file_name              => undef,
    dimensions             => undef,
    rotation               => undef,
    standard_deviation     => undef,
    proportion_of_variance => undef,
    cumulative_proportion  => undef,
    vertices               => undef,
    min_vertex             => undef,
    max_vertex             => undef
  };
  bless $self => $class;
  if (not defined $params{file_name} || not -e $params{file_name}) {
    # No parameters supplied, throw error
    print "Error in call to Pigeon::Data::PCA, no file name supplied.\n";
    print "Syntax: new Pigeon::Data::PCA(file_name=>'filename')\n";
    return;
  }
  if (not defined $params{name}) {
    $params{name} = $params{file_name};
  }
  if (not defined $params{dimensions}) {
    $params{dimensions} = 3;
  }
  $self->{name} = $params{name};
  $self->{file_name} = $params{file_name};
  $self->{dimensions} = $params{dimensions};
  $self->_initialize;
  if (defined $params{threeD}) {
    $self->_parse_threeD;
  }
  else {
    $self->_parse_pca;
  }
  $self->_calc_vertices;
  return $self;
}

=head2 ids

  Title    : ids
  Usage    : my @ids = $pca->ids();
  Function : Returns a list of IDs stored in this object.
  Returns  : List of IDs stored in this object.

=cut

sub ids {
  my $self = shift;
  return keys %{$self->{vertices}};
}

=head2 vertex

  Title    : vertex
  Usage    : my $vertex = $pca->vertex(id => 'vertex id');
  Function : Returns the vertex stored in this object with the given ID.
  Returns  : The vertex stored in this object with the given ID.
  Args     : id {The ID of the vertex to return}

=cut

sub vertex {
  my $self = shift;
  my %params = @_;
  if (defined $params{id} && defined $self->{vertices}{$params{id}}) {
    return @{$self->{vertices}{$params{id}}};
  }
}

=head2 vertices

  Title    : vertices
  Usage    : my $vertices = $pca->vertices();
  Function : Returns the vertices stored in this object.
  Returns  : The vertices stored in this object.

=cut

sub vertices {
  my $self = shift;
  return $self->{vertices};
}

=head2 min_vertex

  Title    : min_vertex
  Usage    : $pca->min_vertex();
  Function : Returns the minimum vertex of this PCA data.
  Returns  : The minimum vertex of this PCA data.

=cut

sub min_vertex {
  my $self = shift;
  return $self->{min_vertex};
}

=head2 max_vertex

  Title    : max_vertex
  Usage    : $pca->max_vertex();
  Function : Returns the maximum vertex of this PCA data.
  Returns  : The maximum vertex of this PCA data.

=cut

sub max_vertex {
  my $self = shift;
  return $self->{max_vertex};
}

=head2 _initialize

  Title    : _initialize
  Usage    : private
  Function : Initializes data for this PCA.

=cut

sub _initialize {
  my $self = shift;
  for (my $d = 0; $d < $self->{dimensions}; $d ++) {
    $self->{min_vertex}->[$d] = $int_max;
    $self->{max_vertex}->[$d] = $int_min;
  }
}

=head2 _parse_pca

  Title    : _parse_pca
  Usage    : private
  Function : Imports a Principal Component Analysis file generated with R
             
=cut

sub _parse_pca {
  my $self = shift;
  my (@headers);
  my $section;
  open (PCA, $self->{file_name}) or die "Can't open R PCA data: $!\n";
    while (my $line = <PCA>) {
      chomp $line;
      # Search for the data start and stop indicators in the file.
      if ($line =~ /^Standard deviations:/) {
        $section = 'stdev';
        next;
      }
      elsif ($line =~ /^Rotation:/) {
        $section = 'rotation';
        next;
      }
      elsif ($line =~ /^Importance of components:/) {
        $section = 'importance';
        next;
      }
      elsif ($line =~ /reached getOption\("max.print"\)/) {
        $section = '';
        print 'Error: getOption("max.print") reached in ' . $self->{file_name} . ", continuing.\n";
        next;
      }
      # Parse Standard deviations section.
      if ($section eq 'stdev') {

      }
      # Parse Rotation section.
      if ($section eq 'rotation') {
        # Line contains either headers or data
        if ($line =~ /^\s+PC\d+/) {
          ($_, @headers) = split(/\s+/, $line);
        }
        else {
          my ($id, @data) = split(/\s+/, $line);
          if ($id =~ /^scf/) {
            substr ($id, 0, 3) = ""
          }
          for (my $i = 0; $i < @data; $i++) {
            ($_, my $pc) = split(/PC/, $headers[$i]);
            $pc --;
            $self->{rotation}{$id}->[$pc] = $data[$i];
          }
        }
      }
      # Parse Importance section.
      if ($section eq 'importance') {
        # Line contains either headers or data
        if ($line =~ /^\s+PC\d+/) {
          ($_, @headers) = split(/\s+/, $line);
        }
        elsif ($line =~ /^(Standard deviation|Proportion of Variance|Cumulative Proportion)\s+(.*)/) {
          my $type = $1;
          my @data = split (/\s+/, $2);
          for (my $i = 0; $i < @data; $i++) {
            ($_, my $pc) = split(/PC/, $headers[$i]);
            $pc --;
            if ($type =~ /^Standard deviation/) {
              $self->{standard_deviation}->[$pc] = $data[$i];
            }
            if ($type =~ /^Proportion of Variance/) {
              $self->{proportion_of_variance}->[$pc] = $data[$i];
            }
            if ($type =~ /^Cumulative Proportion/) {
              $self->{cumulative_proportion}->[$pc] = $data[$i];
            }
          }
        }
      }
    }
  close (PCA);
}

=head2 _parse_threeD

  Title    : _parse_threeD
  Usage    : private
  Function : Imports a threeD file generated with JCVI's threeD plotting program
             
=cut

sub _parse_threeD {
  my $self = shift;
#  my $input = @_;
#  my %data;
  my @headers;
  open (INPUT, $self->{file_name}) or die "Can't open JCVI threeD data: $!\n";
  foreach my $line (<INPUT>) {
    chomp $line;
    if ($line =~ /^-/) {
      @headers = split (/\t/, $line);
      $self->{'headers'} = [ @headers ];
    }
    else {
      my @line = split (/\t/,$line);
      my $scafslice = $line[0];
      $self->{threeD}{$scafslice} = [ @line ];
      $self->{rotation}{$scafslice} = [ $line[3], $line[4], $line[5] ];
    }
  }
  close (INPUT);
}

=head2 _calc_vertices

  Title    : _calc_vertices
  Usage    : private
  Function : Calculates the vertices for the number of dimensions required.
             This multiples the Rotation by the Proportion of Variance for
             each dimension.

=cut

sub _calc_vertices {
  my $self = shift;
  foreach my $id (keys %{$self->{rotation}}) {
    for (my $d = 0; $d < $self->{dimensions}; $d++) {

      $self->{vertices}{$id}->[$d] = $self->{rotation}{$id}->[$d];
#      $self->{vertices}{$id}->[$d] = $self->{rotation}{$id}->[$d] * $self->{proportion_of_variance}->[$d];

      if ($self->{vertices}{$id}->[$d] < $self->{min_vertex}->[$d]) {
        $self->{min_vertex}->[$d] = $self->{vertices}{$id}->[$d];
      }
      if ($self->{vertices}{$id}->[$d] > $self->{max_vertex}->[$d]) {
        $self->{max_vertex}->[$d] = $self->{vertices}{$id}->[$d];
      }
    }
  }
}

1;
__END__


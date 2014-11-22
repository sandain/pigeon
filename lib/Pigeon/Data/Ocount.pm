=head1 NAME

  Pigeon::Data::Ocount

=head1 SYNOPSIS

  Private usage by Pigeon.

=head1 DESCRIPTION

  This package creates a Pigeon::Data::Ocount object to handle the
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

package Pigeon::Data::Ocount;

use strict;
use warnings;

=head2 new

  Title    : new
  Usage    : private
  Function : Creates a new Pigeon::Data::Ocount object
  Returns  : New Pigeon::Data::Ocount object
  Args     : name {name of this Ocount}
             file_name {File name of Ocount data to load}
             dimensions {Number of dimensions to import}

=cut

sub new {
  my $invocant = shift;
  my %params = @_;
  my $class = ref($invocant) || $invocant;
  my $self = {
    name                   => undef,
    file_name              => undef,
  };
  bless $self => $class;
  if (not defined $params{file_name} || not -e $params{file_name}) {
    # No parameters supplied, throw error
    print "Error in call to Pigeon::Data::Ocount, no file name supplied.\n";
    print "Syntax: new Pigeon::Data::Ocount(file_name=>'filename')\n";
    return;
  }
  if (not defined $params{name}) {
    $params{name} = $params{file_name};
  }
  $self->{name} = $params{name};
  $self->{file_name} = $params{file_name};

  $self->_parse_ocounts;
  return $self;
}

=head2 ids

  Title    : ids
  Usage    : my @ids = $ocount->ids();
  Function : Returns a list of IDs stored in this object.
  Returns  : List of IDs stored in this object.

=cut

sub ids {
  my $self = shift;
  return keys %{$self->{vertices}};
}

=head2 vertex

  Title    : vertex
  Usage    : my $vertex = $ocount->vertex(id => 'vertex id');
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
  Usage    : my $vertices = $ocount->vertices();
  Function : Returns the vertices stored in this object.
  Returns  : The vertices stored in this object.

=cut

sub vertices {
  my $self = shift;
  return $self->{vertices};
}

=head2 min_vertex

  Title    : min_vertex
  Usage    : $ocount->min_vertex();
  Function : Returns the minimum vertex of this ocount data.
  Returns  : The minimum vertex of this ocount data.

=cut

sub min_vertex {
  my $self = shift;
  return $self->{min_vertex};
}

=head2 max_vertex

  Title    : max_vertex
  Usage    : $ocount->max_vertex();
  Function : Returns the maximum vertex of this ocount data.
  Returns  : The maximum vertex of this ocount data.

=cut

sub max_vertex {
  my $self = shift;
  return $self->{max_vertex};
}

=head2 _parse_ocounts

  Title    : _parse_ocounts
  Usage    : private
  Function : Imports a matrix of oligocounts generated with TETRA
             
=cut

sub _parse_ocounts {
  my $self = shift;
  my (@headers);
  my $start = 0;
  open (OCOUNT, $self->{file_name}) or die "Can't open oligocount data: $!\n";
    while (my $line = <OCOUNT>) {
      chomp $line;
      if ($start == 0) {
        @headers = split(/\s+/, $line);
        foreach my $i (0..$#headers) {
          if ($headers[$i] =~ /^scf/) {
            substr ($headers[$i], 0, 3) = "";
          }
        }
        $start = 1;
      }
      else {
        my @data = split(/\s+/, $line);
        foreach my $i (0..$#data) {
          push (@{$self->{vertices}->{$headers[$i]}}, $data[$i]);
        }
      }
    }
  $self->{dimensions} = scalar @{ $self->{vertices}{$headers[0]} };
  close (OCOUNT);
}

1;
__END__

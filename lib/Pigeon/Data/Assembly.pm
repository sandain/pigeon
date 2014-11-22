=head1 NAME

  Pigeon::Data::Assembly

=head1 SYNOPSIS

  Private usage by Pigeon.

=head1 DESCRIPTION

  This package creates a Pigeon::Data::Assembly object.

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

package Pigeon::Data::Assembly;

use strict;
use warnings;

=head2 new

  Title    : new
  Usage    : private
  Function : Creates a new Pigeon::Data::Assembly object
  Returns  : New Pigeon::Data::Assembly object
  Args     : name {name of this Assembly}
             file_name {File name of the Assembly data to load}

=cut

sub new {
  my $invocant = shift;
  my %params = @_;
  my $class = ref($invocant) || $invocant;
  my $self = {
    name          => undef,
    assembly_file => undef,
    size_file     => undef,
    gene_file     => undef,
  };

  bless $self => $class;
  if (
    defined $params{assembly_file} && -e $params{assembly_file} &&
    defined $params{size_file} && -e $params{size_file} &&
    defined $params{gene_file} && -e $params{gene_file}
  ) {
    if (not defined $params{name}) {
      $params{name} = $params{assembly_file};
    }
    $self->{name} = $params{name};
    $self->{assembly_file} = $params{assembly_file};
    $self->{size_file} = $params{size_file};
    $self->{gene_file} = $params{gene_file};
    $self->_parse_assembly_file;
    $self->_parse_size_file;
    $self->_parse_gene_file;
    return $self;
  }
  else {
    # No parameters supplied, throw error
    print "Error in call to Pigeon::Data::Assembly, no filenames supplied,\n";
    print "or files are inaccessible.\n";
    return;
  }
}

=head2 ids

  Title    : ids
  Usage    : my @ids = $assembly->ids();
  Function : Returns a list of IDs stored in this object.
  Returns  : List of IDs stored in this object.

=cut

sub ids {
  my $self = shift;
  return keys %{$self->{assembly}};
}

=head2 reads

  Title    : reads
  Usage    : my @reads = $assembly->reads(id => 'id');
  Function : Returns an array containing the reads associated with the provided ID.
  Returns  : An array containing the reads associated with the provided ID
  Args     : id 

=cut

sub reads {
  my $self = shift;
  my %params = @_;
  if (defined $params{id} && defined $self->{assembly}{$params{id}} && defined $self->{assembly}{$params{id}}{reads}) {
    return @{$self->{assembly}{$params{id}}{reads}};
  }
}

=head2 size

  Title    : size
  Usage    : my $size = $assembly->size(id => 'id');
  Function : Returns the size of the contig labeled with the provided ID.
  Returns  : The size of the contig labeled with the provided ID
  Args     : id 

=cut

sub size {
  my $self = shift;
  my %params = @_;
  if (defined $params{id} && defined $self->{assembly}{$params{id}} && defined $self->{assembly}{$params{id}}{size}) {
    return $self->{assembly}{$params{id}}{size};
  }
  else {
    return 0;
  }
}

=head2 gene

  Title    : gene
  Usage    : my $gene = $assembly->gene(id => 'id');
  Function : Returns the gene associated with the provided ID.
  Returns  : The gene associated with the provided ID
  Args     : id 

=cut

sub gene {
  my $self = shift;
  my %params = @_;
  if (defined $params{id} && defined $self->{assembly}{$params{id}} && defined $self->{assembly}{$params{id}}{gene}) {
    return $self->{assembly}{$params{id}}{gene};
  }
  else {
    return '';
  }
}

=head2 _parse_assembly_file

  Title     : _parse_assembly_file
  Usage    : private
  Function : 

=cut

sub _parse_assembly_file {
  my $self = shift;
  open (FILE, $self->{assembly_file}) or die "Can't open assembly file " . $self->{assembly_file} . ": " . $! . "\n";
  while (my $line = <FILE>) {
    if ($line =~ /^(\w+)\s+(\w+)\s+(\w+)\s+(\w+)\s+(\w+)\s+/) {
      my ($id, $key, $start, $stop, $strand) = ($1, $2, $3, $4, $5);
      push (@{$self->{assembly}{$key}{reads}}, $id);
    }
  }
  close FILE;
}

=head2 _parse_size_file

  Title    : _parse_size_file
  Usage    : private
  Function : 

=cut

sub _parse_size_file {
  my $self = shift;
  open (FILE, $self->{size_file}) or die "Can't open assembly size file " . $self->{size_file} . ": " . $! . "\n";
  while (my $line = <FILE>) {
    if ($line =~ /^(\w+)\s+(\d+)/) {
      my ($id, $size) = ($1, $2);
      if ($id =~ /^scf/) {
        substr ($id, 0, 3) = ""
      }
      $self->{assembly}{$id}{size} = $size;
    }
  }
  close FILE;
}

=head2 _parse_gene_file

  Title    : _parse_gene_file
  Usage    : private
  Function : 

=cut

sub _parse_gene_file {
  my $self = shift;
  open (FILE, $self->{gene_file}) or die "Can't open assembly gene file " . $self->{gene_file} . ": " . $! . "\n";
  while (my $line = <FILE>) {
    if ($line =~ /^(\w+)\s+(\w+)/) {
      my ($id, $gene) = ($1, $2);
      if ($id =~ /^scf/) {
        substr ($id, 0, 3) = "";
      }
      $self->{assembly}{$id}{gene} = $gene;
    }
  }
  close FILE;
}

1;
__END__


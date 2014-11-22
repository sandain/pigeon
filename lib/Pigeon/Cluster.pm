=head1 NAME

  Pigeon::Cluster

=head1 SYNOPSIS

  Private usage by Pigeon.

=head1 DESCRIPTION

  This package creates a Pigeon::Cluster object to handle the clustering of Pigeon data.

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

=cut

package Pigeon::Cluster;

use strict;
use warnings;

use Pigeon::Tools qw(:all);
use Pigeon::Statistics;

my $intMax = 100000;
my $intMin = -100000;

my $defaultAlpha = 0.0001;

## Private Methods.

my $clusterMean = sub {
  my $self = shift;
  my @ids = @_;
  my @data;
  if (@ids > 0) {
    # Examine each vertex in the array for given cluster.
    foreach my $id (@ids) {
      for (my $d = 0; $d < @{$self->{vertices}{$id}}; $d++) {
        if (not defined $data[$d]) {
          $data[$d] = 0;
        }
        $data[$d] += $self->{vertices}{$id}->[$d];
      }
    }
    # Calculate the mean of each dimension.
    for (my $d = 0; $d < @data; $d ++) {
      $data[$d] = $data[$d] / @ids;
    }
  }
  return \@data;
};

my $minMax = sub {
  my $self = shift;
  my @ids = @_;
  my (@min, @max);
  foreach my $id (@ids) {
    for (my $d = 0; $d < @{$self->{vertices}{$id}}; $d ++) {
      if (not defined $min[$d]) {
        $min[$d] = $intMax;
      }
      if (not defined $max[$d]) {
        $max[$d] = $intMin;
      }
      if ($self->{vertices}{$id}->[$d] < $min[$d]) {
        $min[$d] = $self->{vertices}{$id}->[$d];
      }
      if ($self->{vertices}{$id}->[$d] > $max[$d]) {
        $max[$d] = $self->{vertices}{$id}->[$d];
      }
    }
  }
  return (\@min, \@max);
};

my $squaredErrorDistortion = sub {
  my $self = shift;
  my %params = @_;
  if (@{$params{ids}} > 0) {
    my $sum = 0;
    foreach my $id (@{$params{ids}}) {
      $sum += distance ($self->{vertices}{$id}, $params{partition}) ** 2;
    }
    return $sum / @{$params{ids}};
  }
};

my $testCluster = sub {
  my $self = shift;
  my %params = @_;
  my $statistics = new Pigeon::Statistics();
  my $data;
  for (my $i = 0; $i < @{$params{ids}}; $i ++) {
    for (my $j = 0; $j < @{$self->{vertices}{$params{ids}->[$i]}}; $j ++) {
      $data->[$i][$j] = $self->{vertices}{$params{ids}->[$i]}->[$j];
    }
  }
  my ($sdev, $rotation, $scores, $center, $scale) = $statistics->pca ($data);
  my (@scores, @rotation);
  for (my $i = 0; $i < @{$rotation}; $i ++) {
    $rotation[$i] = $rotation->[$i][0];
  }
  for (my $i = 0; $i < @{$scores}; $i ++) {
    $scores[$i] = $scores->[$i][0];
  }
  my ($test, $w, $pvalue) = $statistics->shapiro_wilk (\@scores, $params{alpha});
  return ($test, $center, $sdev->[0], \@rotation);
};

my $translate = sub {
  my $self = shift;
  my %params = @_;
  my $translation;
  my $r = 0;
  for (my $d = 0; $d < @{$params{center}}; $d ++) {
    $r += $params{rotation}->[$d] ** 2;
  }
  my $t = sqrt (($params{sdev} ** 2) / $r);
  for (my $d = 0; $d < @{$params{center}}; $d ++) {
    $translation->[0][$d] = $params{center}->[$d] + $params{rotation}->[$d] * $t;
    $translation->[1][$d] = $params{center}->[$d] - $params{rotation}->[$d] * $t;
  }
  return $translation;
};

my $testPartition = sub {
  my $self = shift;
  my %params = @_;
  my ($test, $center, $sdev, $rotation) = $self->$testCluster (
    ids   => $params{ids},
    alpha => $params{alpha}
  );
  if (not $test) {
    return $self->$translate (
      center   => $center,
      sdev     => $sdev,
      rotation => $rotation
    );
  }
  return [$params{partition}];
};

my $kMeans = sub {
  my $self = shift;
  my %params = @_;
  my ($minVertex, $maxVertex) = $self->$minMax (@{$params{ids}});
  my (%clusters, @partitions);
  my $previous_error = 0;
  my $combined_error = 0;
  my $delta_error = 1;
  my $counter = 0;
  if (defined $params{partitions}) {
    @partitions = @{$params{partitions}};
  }
  else {
    # Init $k partitions with a random n dinmensional coordinate within the bounds of minVertex and maxVertex
    for (my $i = 0; $i < $params{k}; $i ++) {
      for (my $d = 0; $d < @{$minVertex}; $d ++) {
        $partitions[$i][$d] = random (low => $minVertex->[$d], high => $maxVertex->[$d]);
      }
    }
  }
  while ($delta_error > 0) {
    my @ids = ();
    # Cluster based on closeness to partitions
    foreach my $id (@{$params{ids}}) {
      my $closest = $intMax;
      my $index;
      for (my $i = 0; $i < $params{k}; $i ++) {
        my $distance = distance ($self->{vertices}{$id}, $partitions[$i]);
        if ($distance < $closest) {
          $closest = $distance;
          $index = $i;
        } 
      }
      $clusters{$id} = $index;
      push (@{$ids[$index]}, $id);
    }
    $previous_error = $combined_error;
    $combined_error = 0;
    # Move non-empty partitions
    for (my $i = 0; $i < $params{k}; $i ++) {
      if (defined $ids[$i]) {
        $partitions[$i] = $self->$clusterMean (@{$ids[$i]});
        $combined_error += $self->$squaredErrorDistortion (ids => $ids[$i], partition => $partitions[$i]);
      }
    }
    $delta_error = $combined_error - $previous_error;
    $counter ++;
  }
  return (\%clusters, \@partitions, $combined_error);
};

# G-Means is based on the algorithm published in the paper:
# Greg Hamerly, Charles Elkan (2003)
# Learning the k in k-means
# Neural Information Processing Systems
my $gMeans = sub {
  my $self = shift;
  my %params = @_;
  my ($clusters, $partitions, $residual_error);
  my $k = 1;
  my $pk = 0;
  # Create the initial partition (average of all points)
  $partitions->[0] = $self->$clusterMean (@{$params{ids}});
  foreach my $id (@{$params{ids}}) {
    $clusters->{$id} = 0;
  }
  while ($k != $pk) {
    $pk = $k;
    # Check each cluster for normality.
    for (my $i = 0; $i < $k; $i ++) {
      my @ids;
      foreach my $id (@{$params{ids}}) {
        if ($clusters->{$id} == $i) {
          push @ids, $id;
        }
      }
      if (@ids > 2) {
        my $p = $self->$testPartition (
          ids       => \@ids,
          partition => shift @{$partitions},
          alpha     => $params{alpha}
        );
        push @{$partitions}, @{$p};
      }
      # Run k-means.
      ($clusters, $partitions, $residual_error) = $self->$kMeans (
        k          => scalar @{$partitions},
        ids        => $params{ids},
        partitions => $partitions,
      );
      last if (@{$partitions} > $k);
    }
    $k = @{$partitions};
  }
  return ($clusters, $partitions, $residual_error);
};

## Public Methods.

=head2 new

  Title    : new
  Usage    : 
  Function : Creates a new Pigeon::Cluster object
  Returns  : New Pigeon::Cluster object
  Params   : vertices - Array reference to the vertices to cluster
             algorithm - Use either kmeans or gmeans
             k - Number of clusters to try to generate, required if using kmeans
             alpha - Alpha level to use to test for type 1 and type 2 errors

=cut

sub new {
  my $invocant = shift;
  my %params = @_;
  my $class = ref($invocant) || $invocant;
  my $self = {
    algorithm  => undef,
    vertices   => undef,
    clusters   => undef,
    partitions => undef,
    error      => undef
  };
  bless $self => $class;
  if (not defined $params{alpha}) {
    $params{alpha} = $defaultAlpha;
  }
  if (defined $params{algorithm} && defined $params{vertices}) {
    # Store the algorithm, vertices.
    $self->{algorithm} = $params{algorithm};
    $self->{vertices} = $params{vertices};
    my @ids = keys %{$params{vertices}};
    # Run the clustering algorithm.
    if (lc $params{algorithm} eq 'kmeans') {
      if (defined $params{k}) {
        ($self->{clusters}, $self->{partitions}, $self->{error}) = $self->$kMeans (
          k   => $params{k},
          ids => \@ids
        );
      }
      else {
        print "Error in call to kmeans, k was not supplied.\n";
      }
    }
    elsif (lc $params{algorithm} eq 'gmeans') {
      ($self->{clusters}, $self->{partitions}, $self->{error}) = $self->$gMeans (
        alpha => $params{alpha},
        ids   => \@ids
      );
    }
  }
  else {
    # No parameters supplied, throw error
    print "Error in call to Pigeon::Cluster, no parameters supplied.\n";
    print "Syntax: new Pigeon::Cluster(algorithm => <algorithm>, vertices => <vertices hash reference>)\n";
  }
  return $self;
}

=head2 getClusters

  Title    : getClusters
  Usage    : 
  Function : Returns the cluster and vertices in PCA space for each sequence.
  Returns  : A hash of clusters and vertices for each sequence.

=cut

sub getClusters {
  my $self = shift;
  my $clusters;
  foreach my $id (keys %{$self->{vertices}}) {
    $clusters->{$id} = {
      vertices => $self->{vertices}{$id},
      cluster  => $self->{clusters}{$id}
    };
  }
  return $clusters;
}

=head2 cluster

  Title    : cluster
  Usage    : my $c = $cluster->cluster (id => 'vertex_id');
  Function : Returns the cluster that the given vertex belongs to.
  Returns  : The cluster the given vertex belongs to.
  Params   : id - The ID of the vertex to return the cluster of

=cut

sub cluster {
  my $self = shift;
  my %params = @_;
  if (defined $params{id} && defined $self->{clusters}{$params{id}}) {
    return $self->{clusters}{$params{id}};
  }
}

=head2 clusters

  Title    : clusters
  Usage    : my $c = $cluster->clusters ();
  Function : Returns the clusters stored in this object.
  Returns  : The clusters stored in this object.

=cut

sub clusters {
  my $self = shift;
  return $self->{clusters};
}

=head2 ids

  Title    : ids
  Usage    : my @ids = $cluster->ids();
  Function : Returns a list of IDs stored in this object.
  Returns  : List of IDs stored in this object.

=cut

sub ids {
  my $self = shift;
  return keys %{$self->{vertices}};
}

=head2 vertex

  Title    : vertex
  Usage    : my $vertex = $cluster->vertex(id => 'vertex id');
  Function : Returns the vertex stored in this object with the given ID.
  Returns  : The vertex stored in this object with the given ID.
  Params   : id - The ID of the vertex to return

=cut

sub vertex {
  my $self = shift;
  my %params = @_;
  return $self->{vertices}{$params{id}};
}

=head2 vertices

  Title    : vertices
  Usage    : my $vertices = $cluster->vertices();
  Function : Returns the vertices stored in this object.
  Returns  : The vertices stored in this object.

=cut

sub vertices {
  my $self = shift;
  return $self->{vertices};
}

=head2 partition

  Title    : partition
  Usage    : my @vertex = $cluster->partition(cluster => 1);
  Function : Returns the partition of the cluster requested.
  Returns  : The partition of the cluster requested.
  Params   : cluster - The cluster number to return

=cut

sub partition {
  my $self = shift;
  my %params = @_;
  if (defined $params{cluster} and defined $self->{partitions}->[$params{cluster}]) {
    return $self->{partitions}->[$params{cluster}];
  } 
}

=head2 partitions

  Title    : partitions
  Usage    : my @partitions = $cluster->partitions();
  Function : Returns an array of the the partitions.
  Returns  : An array of the partitions.

=cut

sub partitions {
  my $self = shift;
  return $self->{partitions};
}

=head2 error

  Title    : error
  Usage    : my $error = $cluster->error();
  Function : Returns the residual squared error distortion of this cluster.
  Returns  : The residual squared error distortion of this cluster.

=cut

sub error {
  my $self = shift;
  return $self->{error};
}

1;

__END__


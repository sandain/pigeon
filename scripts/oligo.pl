#! /usr/bin/perl

=head1 NAME

  Oligo

=head1 SYNOPSIS

  A program to perform clustering of metagenomic sequence data.

=head1 DESCRIPTION

  This program performs k-means clustering (Lloyd 1957) of metagenomic
  sequence data.  It is based on code originally written to analyze
  metagenomic sequence data obtained from Mushroom and Octopus Springs of
  Yellowstone National Park (Klatt et al. 2011).

  The program fractionates the provided sequence data into equal sized chunks
  to be quantized into a n-dimensional space based on the oligonucleotide
  usage frequency.  The number of dimensions, and hence the computation time,
  is a result of the length of oligonucleotides requested (4^6 dimensions for
  all possible hexamers).  K-means clustering using Lloyd's algorithm is then
  run a number of times to create a pairwise-comparison matrix of how often
  sequences end up in the same cluster.  Sequences that cluster together more
  often than the bootstrap cutoff percentage value are demarcated as being in
  the same cluster.

  Output files:
    cluster_N.fa - The sequence data for cluster N.
    cluster_N.tsv - The pairwise-comparison matrix for cluster N.

=head1 DEPENDENCIES

  BioPerl : CPAN : L<http://search.cpan.org/perldoc?BioPerl>
            Website : L<http://www.bioperl.org/>
            Paper : Stajich et al. 2002.

  POSIX   : CPAN : L<http://search.cpan.org/perldoc?POSIX>

=head1 FEEDBACK

=head2 Mailing Lists

  No mailing list currently exists.

=head2 Reporting Bugs

  Report bugs to the author directly.

=head1 AUTHOR

  Jason M. Wood
  Dept. Land Resources and Environmental Sciences
  Montana State University

  Email: sandain-at-hotmail.com

=head1 REFERENCES

  Klatt, CG, JM Wood, DB Rusch, MM Bateson, N Hamamura, JF Heidelberg,
    AR Grossman, D Bhaya, FM Cohan, M Kühl, DA Bryant, and DM Ward. 2011.
    Community ecology of hot spring cyanobacterial mats: predominant
    populations and their functional potential. ISME J. 5:1262-1278.
    L<http://dx.doi.org/10.1038/ismej.2011.73>

  Lloyd, SP. 1957. Least squares quantization in PCM. IEEE Transactions on
    Information Theory IT-28:129-137. 
    L<http://dx.doi.org/10.1109/TIT.1982.1056489>

  Stajich, JE, D Block, K Boulez, SE BrennerE, SA Chervitz, C Dagdigian,
    G Fuellen, JG Gilbert, I Korf, H Lapp, H Lehväslaiho, C Matsalla,
    CJ Mungall, BI Osborne, MR Pocock, P Schattner, M Senger, LD Stein,
    E Stupka, MD Wilkinson, and E Birney. 2002. The Bioperl toolkit: Perl
    modules for the life sciences. Genome Res. 12(10):1611-8.
    L<http://dx.doi.org/10.1101/gr.361602>

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2013  Jason M. Wood

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

use strict;
use warnings;

use Bio::SeqIO;
use POSIX;

# Print debugging data.
#   0  : Don't print debugging data.
#   1  : Print debugging data.
#   >1 : Print verbose debugging data.
my $DEBUG = 0;

# Build the command line usage statement.
my $usage = sprintf "Usage: %s <%s>\n", $0, join ('> <',
  'Fasta File',
  'K Value',
  'Fragment Length',
  'Oligo Length',
  'Number of Trials',
  'Bootstrap Cutoff'
);

# Check the command line arguments.
my (
  $inputFile,       # The file containing metagenomic sequences to cluster.
  $k,               # The k value to use in clustering.
  $fragmentLength,  # The length of sequence fragments to use in clustering.
  $oligoLength,     # The length of oligo to use in quantizing the sequences.
  $numTrials,       # The number of trails to run.  Default to 100.
  $cutoff           # The bootstrap cutoff percentage value.  Default to 0.9.
) = verifyArguments (@ARGV);

# Chop the input sequences into appropriately sized fragments.
print "Chopping sequences...\n" if ($DEBUG);
my $sequences = chopSequences (
  $inputFile,
  $fragmentLength,
);
my @ids = keys %{$sequences};

# Output the sequences if verbose debugging is turned on.
if ($DEBUG > 1) {
  print "Sequences:\n";
  foreach my $id (@ids) {
    print $id . "\t";
    print $sequences->{$id}->seq() . "\n";
  }
}

# Generate the set of possible oligonucleotides for the provided lengths.
print "Generating all possible oligonucleotides...\n" if ($DEBUG);
my $oligos = generateSet($oligoLength);

# Output the oligonucleotides if verbose debugging is turned on.
if ($DEBUG > 1) {
  print "Oligonucleotides:\n";
  foreach my $oligo (@{$oligos}) {
    print $oligo . " ";
  }
  print "\n";
}

# Create the vertices by quantizing the oligo usage frequency for all
# sequences.
print "Generating vertices...\n" if ($DEBUG);
my $vertices = generateVertices (
  $sequences,
  $oligos
);

# Output the vertices if verbose debugging is turned on.
if ($DEBUG > 1) {
  print "Vertices:\n";
  foreach my $id (@ids) {
    printf $id . "\t";
    for (my $i = 0; $i < @{$vertices->{$id}}; $i ++) {
      print $vertices->{$id}[$i] . ' ';
    }
    print "\n";
  }
}

# Create a pairwise comparison matrix of clustering results.
print "Running kmeans clustering trials...\n" if ($DEBUG);
my $matrix;
for (my $trial = 0; $trial < $numTrials; $trial ++) {
  print "Running trial " . ($trial + 1) . "...\n" if ($DEBUG);
  my ($clusters, $partitions, $error) = kmeans ($k, $vertices, \@ids);
  # Print the cluster of each sequence if verbose debugging is turned on.
  if ($DEBUG > 1) {
    foreach my $id (@ids) {
      print $id . "\tcluster " . $clusters->{$id} . "\n";
    }
    print "\n";
  }
  # Add this clustering run to the pairwise comparison matrix.
  for (my $i = 0; $i < @ids; $i ++) {
    for (my $j = 0; $j < $i; $j ++) {
      if ($clusters->{$ids[$i]} eq $clusters->{$ids[$j]}) {
        $matrix->[$i][$j] ++;
      }
    }
  }
}

# Create a graph from the count matrix.
print "Generating a graph from the clustering trials...\n" if ($DEBUG);
my $graph = {};
for (my $i = 0; $i < @ids; $i ++) {
  for (my $j = 0; $j < $i; $j ++) {
    my $edge = defined $matrix->[$i][$j] ? $matrix->[$i][$j] / $numTrials : 0;
    next if ($edge < $cutoff);
    # Add edges to the graph.
    $graph->{$ids[$i]}->{$ids[$j]} = $edge;
    $graph->{$ids[$j]}->{$ids[$i]} = $edge;
  }
}

# Find the connected sub-graphs, and create a tsv file for each.
print "Searching for sub-graphs...\n" if ($DEBUG);
my $i = 0;
foreach my $sg (@{getSubGraphs($graph)}) {
  $i ++;
  my $fileName = sprintf "cluster_%d.tsv", $i;
  open TSV, '>' . $fileName or die "Unable to write to file: $!\n";
  my %seen = ();
  my %subGraphIDs = ();
  foreach my $node1 (keys %{$sg}) {
    $seen{$node1} = 1;
    foreach my $node2 (keys %{$graph->{$node1}}) {
      next if ($seen{$node2});
      printf TSV "%s\t%s\t%s\n", $node1, $node2, $graph->{$node1}->{$node2};
      # Add the sequence identifiers from each node to the list to add to the
      # fasta file.
      $subGraphIDs{$node1} = 1;
      $subGraphIDs{$node2} = 1;
    }
  }
  close TSV;
  # Save a fasta file containing just the sequences from this sub graph.
  my $outIO = new Bio::SeqIO (
    -file   => '>' . 'cluster_' . $i . '.fa',
    -format => 'fasta'
  );
  foreach my $id (keys %subGraphIDs) {
    $outIO->write_seq ($sequences->{$id});
  }
  $outIO->close;
}


=head2 chopSequences

  Title    : chopSequences
  Function : Create a hash reference that contains sequences of the
             appropriate length.
  Args     : inputFile - The file containing the input sequences.
             fragmentLength - The length of fragments to generate.
  Returns  : outputSequences - The generated sequence fragments.

=cut

sub chopSequences {
  my ($inputFile, $fragmentLength) = @_;
  my ($inputSequences, $outputSequences);
  # Load the input sequence file.
  my $inIO = new Bio::SeqIO (
    -file   => '<' . $inputFile,
    -format => 'fasta'
  );
  while (my $seq = $inIO->next_seq) {
    $inputSequences->{$seq->id()} = $seq;
  }
  $inIO->close;
  # Chop up the sequences in the input sequences.
  foreach my $id (keys %{$inputSequences}) {
    my $inputSeq = lc $inputSequences->{$id}->seq();
    # Remove unsupported IUPAC nucleic acid codes.
    $inputSeq =~ s/[rymkwsbdhvn\-\.]+//g;
    # Convert Uracil (U) to Thymine (T).
    $inputSeq =~ s/[Uu]/t/g;
    # Calculate the length of the sequence.
    my $length = length $inputSeq;
    # Randomly choose a number of sequences based on the length of the
    # sequence.
    my $numRandomSequences = floor (2 * $length / $fragmentLength) - 1;
    for (my $i = 0; $i < $numRandomSequences; $i ++) {
      my $index = floor (rand ($length - $fragmentLength));
      my $sequence = substr ($inputSeq, $index, $fragmentLength);
      my $outputID = $id . '_' . $i . '-' . ($i + $fragmentLength);
      $outputSequences->{$outputID} = new Bio::Seq (
        -id   => $outputID,
        -desc => $length,
        -seq  => $sequence
      );
    }
  }
  return $outputSequences;
}


=head2 getConnectedNodes

  Title    : getConnectedNodes
  Function : Create an array that contains the identifiers connected to the
             provided node.
  Args     : graph - The graph of all nodes.
             node - The node to use.
  Returns  : nodes - An array reference containing identifiers of nodes
             connected to the provided node.

=cut

sub getConnectedNodes {
  my ($graph, $node) = @_;
  my $connectedNodes = {$node => 1};
  my @nodes = ($node);
  while (@nodes > 0) {
    my $n = pop @nodes;
    foreach my $neighbor (keys %{$graph->{$n}}) {
      if (not exists $connectedNodes->{$neighbor}) {
        $connectedNodes->{$neighbor} = 1;
        push @nodes, $neighbor;
      }
    }
  }
  return $connectedNodes;
}


=head2 getSubGraphs

  Title    : getSubGraphs
  Function : Create an array of connected sub-graphs, where each element
             contains an array of identifiers in that sub-graph.
  Args     : graph - The graph of all nodes.
  Returns  : subGraphs - An array reference of sub-graph identifiers.

=cut

sub getSubGraphs {
  my ($graph) = @_;
  my $subGraphs = [];
  foreach my $node (keys %{$graph}) {
    my $connected = 0;
    foreach my $connectedNode (@{$subGraphs}) {
      if (exists $connectedNode->{$node}) {
        $connected = 1;
        last;
      }
    }
    if ($connected == 0) {
      push @{$subGraphs}, getConnectedNodes($graph, $node);
    }
  }
  return $subGraphs;
}


=head2 generateVertices

  Title    : generateVertices
  Function : Generate all possible oligonucleotides of the provided length,
             and count the number of times each sequence contains each
             oligonucleotide.
  Args     : sequences - A hash reference containing the sequences to use.
             oligos - A hash reference containing the set of oligos to use
             for quantizing the sequences.
  Returns  : vertices - An array reference containg the oligo usage frequence
             for each sequence.

=cut

sub generateVertices {
  my ($sequences, $oligos) = @_;
  my $vertices;
  # Count the number of times each oligonucleotide appears in each sequence.
  foreach my $id (keys %{$sequences}) {
    my $seq = $sequences->{$id}->seq();
    my @profile;
    foreach my $oligo (@{$oligos}) {
      my $i = 0;
      while ($seq =~ /$oligo/g) {
        $i ++;
      }
      push @profile, $i;
    }
    $vertices->{$id} = \@profile;
  }
  return $vertices;
}


=head2 generateSet

  Title    : generateSet
  Function : Generate a set of oligonucleotides of the correct length.
  Args     : length - The length of the oligonucleotides to generate.
             oligo - The growing oligonucleotide, used privately.
  Returns  : oligos - The set of generated oligonucleotides.

=cut

sub generateSet {
  my ($length, $oligo) = @_;
  my $oligos;
  # Initialize the generating oligo.
  $oligo = '' if (not defined $oligo);
  # Check to see if $oligo is long enough.  If it's not, append the four
  # nucleotides to $oligo and recurse, saving the output in the oligos array.
  # If $oligo is long enough, push it onto the oligos array.
  if ($length > length $oligo) {
    foreach my $nuc ('a', 'c', 'g', 't') {
       my $set = generateSet ($length, $oligo . $nuc);
       push @{$oligos}, @{$set};
    }
  }
  else {
    push @{$oligos}, $oligo;
  }
  return $oligos;
}


=head2 clusterMean

  Title    : clusterMean
  Function : Calculates the mean n-dimensional vertex of a cluster of
             vertices.
  Args     : vertices - All of the oligonucleotide usage vertices.
             ids - The identifiers of sequences in a cluster.
  Returns  : mean - The mean vertex of the cluster.

=cut

sub clusterMean {
  my ($vertices, $ids) = @_;
  my $mean;
  if (@{$ids} > 0) {
    # Examine each vertex in the array for given cluster.
    foreach my $id (@{$ids}) {
      for (my $d = 0; $d < scalar @{$vertices->{$id}}; $d++) {
        if (not defined $mean->[$d]) {
          $mean->[$d] = 0;
        }
        $mean->[$d] += $vertices->{$id}->[$d];
      }
    }
    # Calculate the mean of each dimension.
    for (my $d = 0; $d < scalar @{$mean}; $d ++) {
      $mean->[$d] = $mean->[$d] / scalar @{$ids};
    }
  }
  return $mean;
}


=head2 minMax

  Title    : minMax
  Function : Calculates the min/max vertices of a n-dimensional set of
             vertices.
  Args     : vertices - All of the oligonucleotide usage vertices.
             ids - The identifiers of sequences to min/max.
  Returns  : min - The minimum n-dimensional vertex.
             max - The maximum n-dimensional vertex.

=cut

sub minMax {
  my ($vertices, $ids) = @_;
  my ($min, $max);
  foreach my $id (@{$ids}) {
    for (my $d = 0; $d < @{$vertices->{$id}}; $d ++) {
      if (not defined $min->[$d]) {
        $min->[$d] = INT_MAX;
      }
      if (not defined $max->[$d]) {
        $max->[$d] = INT_MIN;
      }
      if ($vertices->{$id}->[$d] < $min->[$d]) {
        $min->[$d] = $vertices->{$id}->[$d];
      }
      if ($vertices->{$id}->[$d] > $max->[$d]) {
        $max->[$d] = $vertices->{$id}->[$d];
      }
    }
  }
  return ($min, $max);
}


=head2 squaredErrorDistortion

  Title    : squaredErrorDistortion
  Function : Calculates the squared error distortion of a set vertices using a
             Euclidean distance measure.
  Args     : vertices - All of the oligonucleotide usage vertices.
             ids - The identifiers of sequences in a cluster.
             partition - The partition vertex of the cluster.
  Returns  : error - The squared error distortion of the set of vertices.

=cut

sub squaredErrorDistortion {
  my ($vertices, $ids, $partition) = @_;
  my $error = 0;
  if (@{$ids} > 0) {
    my $sum = 0;
    foreach my $id (@{$ids}) {
      $sum += distance ($vertices->{$id}, $partition) ** 2;
    }
    $error = $sum / scalar @{$ids};
  }
  return $error;
}


=head2 distance

  Title    : distance
  Function : Returns the Euclidean distance between the two given
             n-dimensional points.
  Args     : a - Array reference to the n dimensional point A.
             b - Array reference to the n dimensional point B.
  Returns  : distance - The Euclidean distance between the two given
             n-dimensional points.

=cut

sub distance {
  my ($a, $b) = @_;
  my $distance = 0;
  # Calculate the number of dimensions.
  my $dimensions;
  if (@{$a} < @{$b}) {
    $dimensions = @{$a};
  }
  else {
    $dimensions = @{$b};
  }
  # Add up the square of the total distance.
  for (my $n = 0; $n < $dimensions; $n ++) {
    $distance += (($a->[$n] - $b->[$n]) ** 2);
  }
  # Return the square root of the square of the total distance.
  $distance = sqrt $distance;
  return $distance;
}


=head2 kmeans

  Title    : kmeans
  Function : Peforms k-means clustering using Lloyd's algorithm on a set of
             vertices.
  Args     : k - The value of k to use for clustering.
             vertices - All of the oligonucleotide usage vertices.
             ids - The ids to cluster.
  Returns  : clusters - An array reference of clusters.
             partitions - An array reference of paritions for each cluster.
             error - The combined error for the clustering run.

=cut

sub kmeans {
  my ($k, $vertices, $ids) = @_;
  my ($clusters, $partitions, $error);
  # Initialize $k partitions with a random n dimensional coordinate within the
  # min/max vertex bounds.
  my ($minVertex, $maxVertex) = minMax ($vertices, $ids);
  for (my $i = 0; $i < $k; $i ++) {
    for (my $d = 0; $d < @{$minVertex}; $d ++) {
      $partitions->[$i][$d] = 
        rand ($maxVertex->[$d] - $minVertex->[$d]) + $minVertex->[$d];
    }
  }
  my $delta_error = INT_MAX;
  while ($delta_error > 0) {
    my @cluster = ();
    # Cluster based on closeness to partitions
    foreach my $id (@{$ids}) {
      my $closest = INT_MAX;
      my $index;
      for (my $i = 0; $i < $k; $i ++) {
        my $distance = distance ($vertices->{$id}, $partitions->[$i]);
        if ($distance < $closest) {
          $closest = $distance;
          $index = $i;
        } 
      }
      $clusters->{$id} = $index;
      push (@{$cluster[$index]}, $id);
    }
    my $previous_error = defined $error ? $error : 0;
    $error = 0;
    # Move non-empty partitions
    for (my $i = 0; $i < $k; $i ++) {
      if (defined $cluster[$i]) {
        $partitions->[$i] = clusterMean ($vertices, $cluster[$i]);
        $error += squaredErrorDistortion (
          $vertices, $cluster[$i], $partitions->[$i]
        );
      }
    }
    $delta_error = $error - $previous_error;
  }
  return ($clusters, $partitions, $error);
}


=head2 verifyArguments

  Title    : verifyArguments
  Function : Verify the command line arguments.
  Args     : inputFile - The file containing metagenomic sequences to cluster.
             k - The k value to use in clustering.
             fragmentLength - The length of sequence fragments to use in
             clustering.
             oligoLength - The length of oligo to use in quantizing the
             sequences.
             numTrials - The number of trails to run.  Default to 100.
             cutoff - The bootstrap cutoff percentage value.  Default to 0.9.
  Returns  : inputFile - The file containing metagenomic sequences to cluster.
             k - The k value to use in clustering.
             fragmentLength - The length of sequence fragments to use in
             clustering.
             oligoLength - The length of oligo to use in quantizing the
             sequences.
             numTrials - The number of trails to run.  Default to 100.
             cutoff - The bootstrap cutoff percentage value.  Default to 0.9.
=cut

sub verifyArguments {
  my ($inputFile, $k, $fragmentLength, $oligoLength, $numTrials, $cutoff) = @_;
  # The input file is required, print an error message if not defined.
  if (not defined $inputFile) {
    print "Error, the fasta file was not provided.\n";
    print $usage;
    exit;
  }

  # The k value is required, print an error message if not defined.
  if (not defined $k) {
    print "Error, the k value was not provided.\n";
    print $usage;
    exit;
  }

  # The fragment length is not required, provide a default value and print a
  # message if not defined.
  if (not defined $fragmentLength or $fragmentLength <= 0) {
    print "Fragment length not supplied, defaulting 10000.\n";
    $fragmentLength = 10000;
  }

  # The oligo length is not required, provide a default value and print a
  # message if not defined.
  if (not defined $oligoLength or $oligoLength <= 0 or $oligoLength >= 10) {
    print "Oligo length not supplied, defaulting to 4.\n";
    $oligoLength = 4;
  }

  # The number of trials is not required, provide a default value and print a
  # message if not defined.
  if (not defined $numTrials or $numTrials <= 0) {
     print "Number of trials not supplied, defaulting to 100.\n";
    $numTrials = 100;
  }

  # The bootstrap cutoff is not required, provide a default value and print a
  # message if not defined.
  if (not defined $cutoff or $cutoff <= 0.0 or $cutoff >= 1.0) {
    print "Bootstrap cutoff not supplied, defaulting to 0.9.\n";
    $cutoff = 0.9;
  }
  return ($inputFile, $k, $fragmentLength, $oligoLength, $numTrials, $cutoff);
}

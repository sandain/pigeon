=head1 NAME

  Pigeon::Text - Text output package for Pigeon.

=head1 SYNOPSIS

  Private usage by Pigeon.

=head1 DESCRIPTION

  This package creates a Pigeon::Text object.

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

package Pigeon::Text;

use strict;
use warnings;

use Pigeon::Tools qw(:all);
use Pigeon::Statistics;
use Pigeon::Data;

=head2 new

 Title    : new
 Usage    : private
 Function : Creates a new Pigeon::Text object
 Returns  : New Pigeon::Text object
 Args     : pigeon_data {Pigeon::Data object}

=cut

sub new {
  my $invocant = shift;
  my %params = @_;
  my $class = ref($invocant) || $invocant;
  my $self = {
    pigeon_data => undef
  };
  bless $self => $class;
  if (defined $params{pigeon_data}) {
    $self->{pigeon_data} = $params{pigeon_data};
  }
  else {
    # No parameters supplied, throw error
    print "Error in call to Pigeon::Text, no parameters supplied.\n";
    print "Syntax: new Pigeon::Text(<Pigeon::Data object>)\n";
  }
  return $self;
}

=head2 print_unique_bins

  Title    : print_unique_bins
  Usage    : 
  Function : Prints all of the unique bins
  Returns  : 
  Args     : 

=cut

sub print_unique_bins {
  my $self = shift;
  my %params = @_;
  my %reads = $self->{pigeon_data}->reads(%params);
  my %bins = ();
  foreach my $id (keys %reads) {
    $bins{$reads{$id}{bin}} ++;
  }
  print "Bin\t\t\t\t\t\t\tCount\n";
  foreach my $bin (sort keys %bins) {
    if (length($bin) < 8) {
      print "$bin\t\t\t\t\t\t\t$bins{$bin}\n";
    }
    elsif (length($bin) < 16) {
      print "$bin\t\t\t\t\t\t$bins{$bin}\n";
    }
    elsif (length($bin) < 24) {
      print "$bin\t\t\t\t\t$bins{$bin}\n";
    }
    elsif (length($bin) < 32) {
      print "$bin\t\t\t\t$bins{$bin}\n";
    }
    elsif (length($bin) < 40) {
      print "$bin\t\t\t$bins{$bin}\n";
    }
    elsif (length($bin) < 48) {
      print "$bin\t\t$bins{$bin}\n";
    }
    else {
      print "$bin\t$bins{$bin}\n";
    }
  }
}

=head2 print_unique_spring_ids

  Title    : print_unique_spring_ids
  Usage    : 
  Function : Prints all of the unique sping IDs
  Returns  : 
  Args     : 

=cut

sub print_unique_spring_ids {
  my $self = shift;
  my %params = @_;
  my %reads = $self->{pigeon_data}->reads(%params);

  my %ids = ();
  foreach my $id (keys %reads) {
    $ids{substr($id, 0, 3)}++;
  }
  print "ID\tCount\n";
  foreach my $id (sort keys %ids) {
    print "$id\t$ids{$id}\n";
  }
}

=head2 print_categories

  Title    : print_categories
  Usage    : 
  Function : 
  Returns  : 
  Args     : bins {any of the valid bins}
             categories {}
             metagenome {mslow, mshigh, oslow, oshigh, low, high, total}
		mslow:	Mushroom Spring, low temperature
		mshigh: Mushroom Spring, high temperature
		oslow:	Octopus Spring, low temperature, 60*C
		oshigh: Octopus Spring, high temperature, 65*C
		low:	Low temperature, combined sample from both springs
		high:	High temperature, combined sample from both springs
		total:	Combined sample from both springs and both temperatures
             size {2-3 kb, 3-4 kb, 4-5 kb, 5-6 kb, 8-9 kb, 10-12 kb, total, default total}
             extracted {TIGR, MSU, total, default total}
             layer {top 1mm, 1mm below top, bottom 1mm, total, default total}
             file_name {File Name, defaults to '.gif'}
             title {Optional Title, caluclated from $params{metagenome} if not provided}

=cut

sub print_categories {
  my $self = shift;
  my %params = @_;
  # Set default values for inputs.
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
  my %reads = $self->{pigeon_data}->reads(%params);
  my %counter = ();
  # Count the number of reads for each bin and type
  foreach my $id (keys %reads) {
    if (contains (list => $params{bins}, item => $reads{$id}{bin})) {     
      $counter{$reads{$id}{bin}}{$reads{$id}{type}} ++;
    }
  }
  createDirectory (fileName => $params{file_name});
  # Write output to file_name.
  open (FILE, '>' . $params{file_name}) or die "Can't open for write: $!\n";
    if (defined $params{title}) {
      print FILE "$params{title}\n\n";
    }
    # Print X axis labels.
    print FILE "\t";
    foreach my $cat (@{$params{categories}}) {
      printf FILE "%12s", $self->{pigeon_data}->short_description(bin => $cat);
    }
    print FILE "\n";
    # Print Y axis labels and counts.
    foreach my $bin (@{$params{bins}}) {
      print FILE $self->{pigeon_data}->short_description(bin => $bin) . "\t";
      foreach my $cat (@{$params{categories}}) {
        if (not defined $counter{$bin}{$cat}) {
          $counter{$bin}{$cat} = 0;
        }
        printf FILE "%12d", $counter{$bin}{$cat};
      }
      print FILE "\n";
    }
  close (FILE);
}

=head2 print_percent_id

  Title    : print_percent_id
  Usage    : 
  Function : Prints the percent id of each read in the supplied method, bin, and metagenome.
  Returns  : 
  Args     : method {paired, unpaired, nopair, total}
		paired:	  Print only paired reads
		unpaired: Print only unpaired reads
		nopair:	  Print reads with no pair
		total:	  Print all reads: paired, unpaired, and no pair in that order
             bin {any of the valid bins}
             metagenome {mslow, mshigh, oslow, oshigh, low, high, total}
		mslow:	Mushroom Spring, low temperature
		mshigh: Mushroom Spring, high temperature
		oslow:	Octopus Spring, low temperature, 60*C
		oshigh: Octopus Spring, high temperature, 65*C
		low:	Low temperature, combined sample from both springs
		high:	High temperature, combined sample from both springs
		total:	Combined sample from both springs and both temperatures

=cut

sub print_percent_id {
  my $self = shift;
  my %params = @_;
  my %reads = $self->{pigeon_data}->reads(%params);

#  if ($params{method} eq 'paired' || $params{method} eq 'total') {
#    print "Paired: ", $params{bin}, " - ", $params{metagenome}, "\n";
#    print "Read\t\tPercent_ID\n";
#    foreach my $id (sort keys %paired) {
#      if ($reads{$id}{bin} eq $params{bin} && ($reads{$id}{metagenome} =~ /$params{metagenome}/ || $params{metagenome} eq 'total')) {
#        print $id, " F\t", $reads{$id}{percent_identity}, "\n";
#	print $id, " R\t", $reads{$id}{percent_identity}, "\n";
#      }
#    }
#  }
#  if ($params{method} eq 'unpaired' || $params{method} eq 'total') {
#    print "Unpaired: ", $params{bin}, " - ", $params{metagenome}, "\n";
#    print "Read\t\tPercent_ID\n";
#    foreach my $id (sort keys %unpaired) {
#      if ($unpaired{$id}{bin} eq $params{bin} && ($unpaired{$id}{metagenome} =~ /$params{metagenome}/ || $params{metagenome} eq 'total')) {
#        print $id, " F\t", $unpaired{$id}{percent_identity}, "\n";
#      }
#      if ($unpaired{$id}{bin} eq $params{bin} && ($unpaired{$id}{metagenome} =~ /$params{metagenome}/ || $params{metagenome} eq 'total')) {
#        print $id, " R\t", $unpaired{$id}{percent_identity}, "\n";
#      }
#    }
#  }
#  if ($params{method} eq 'nopair' || $params{method} eq 'total') {
#    print "No Pairs: ", $params{bin}, " - ", $params{metagenome}, "\n";
#    print "Read\t\tPercent_ID\n";
#    foreach my $id (sort keys %nopair) {
#      if ($nopair{$id}{bin} eq $params{bin} && ($nopair{$id}{metagenome} =~ /$params{metagenome}/ || $params{metagenome} eq 'total')) {
#        print $id, "\t", $nopair{$id}{percent_identity}, "\n";
#      }
#    }
#  }
}

=head2 average_hit_quality_table

  Title    : average_hit_quality_table
  Usage    : 
  Function : Display the average hit quality for the given bins
  Returns  : 
  Args     : bins {Array reference of bins to test}
             lows {Array reference of low Nt IDs to test}
             highs {Array reference of high Nt IDs to test}
             metagenomes {mslow, mshigh, oslow, oshigh, low, high, total}
		mslow:	Mushroom Spring, low temperature
		mshigh: Mushroom Spring, high temperature
		oslow:	Octopus Spring, low temperature, 60*C
		oshigh: Octopus Spring, high temperature, 65*C
		ms:	Mushroom Spring, combined sample from both temperatures
		os:	Octopus Spring, combined sample from both temperatures
		low:	Low temperature, combined sample from both springs
		high:	High temperature, combined sample from both springs
		total:	Combined sample from both springs and both temperatures (default)
             sizes {2-3 kb, 3-4 kb, 4-5 kb, 5-6 kb, 8-9 kb, 10-12 kb, default total}
             extracted {TIGR, MSU, default total}
             layers {top 1mm, 1mm below top, bottom 1mm, default total}
             file_name {File Name, defaults to 'average_hit_quality_table.txt'}
             title {Title, defaults to 'Average Hit Quality'}

=cut

sub average_hit_quality_table {
  my $self = shift;
  my %params = check_parameters (
    params   => \@_,
    type     => 'text',
    defaults => {
      file_name => 'average_hit_quality_table.txt',
      title     => 'Average Hit Quality',
    }
  );
  my %reads = $self->{pigeon_data}->reads(%params);
  my (@syntenous_counter, @non_syntenous_counter, @unpaired_counter);
  createDirectory (fileName => $params{file_name});
  # Write output to file_name
  open (FILE, '>' . $params{file_name}) or die "Can't open for write: $!\n";
  print FILE "$params{title}\n\n";
  printf FILE "%50s\t%9s\t%12s\t%12s\t%12s\n", "Organism", "Range", "Unpaired", "NonSyntenous", "Syntenous";
  for (my $i = 0; $i < @{$params{bins}}; $i++) {
    $syntenous_counter[$i] = 0;
    $non_syntenous_counter[$i] = 0;
    $unpaired_counter[$i] = 0;
    foreach my $id (keys %reads) {
      if (
        ($reads{$id}{bin} eq ${$params{bins}}[$i]) &&
        ($reads{$id}{percent_identity} >= ${$params{lows}}[$i]) &&
        ($reads{$id}{percent_identity} <= ${$params{highs}}[$i])
      ) {
        if ($reads{$id}{type} eq 'paired_good_good') {
          $syntenous_counter[$i] ++;
        }
        elsif ($reads{$id}{type} =~ /^paired/ && $reads{$id}{type} ne 'paired_na') {
          $non_syntenous_counter[$i] ++;
        }
        elsif ($reads{$id}{type} =~ /^unpaired/) {
          $unpaired_counter[$i] ++;
        }
      }
    }
    printf FILE "%50s\t%3d - %3d\t%12d\t%12d\t%12d\n",
      $self->{pigeon_data}->long_description(bin => ${$params{bins}}[$i]),
      ${$params{lows}}[$i],
      ${$params{highs}}[$i],
      $unpaired_counter[$i],
      $non_syntenous_counter[$i],
      $syntenous_counter[$i]; 
  }
  close (FILE);
}

=head2 unpaired_frequency

  Title    : unpaired_frequency
  Usage    :
  Function : 
  Args     : bins {Array reference containing the two bins to test}
             low {Low percent_id value to return, defaults to 0}
             high {High percent_id value to return, defaults to 100}
             metagenomes {mslow, mshigh, oslow, oshigh, low, high, total}
		mslow:	Mushroom Spring, low temperature
		mshigh: Mushroom Spring, high temperature
		oslow:	Octopus Spring, low temperature, 60*C
		oshigh: Octopus Spring, high temperature, 65*C
		ms:	Mushroom Spring, combined sample from both temperatures
		os:	Octopus Spring, combined sample from both temperatures
		low:	Low temperature, combined sample from both springs
		high:	High temperature, combined sample from both springs
		total:	Combined sample from both springs and both temperatures (default)
             sizes {2-3 kb, 3-4 kb, 4-5 kb, 5-6 kb, 8-9 kb, 10-12 kb, default total}
             extracted {TIGR, MSU, default total}
             layers {top 1mm, 1mm below top, bottom 1mm, default total}
             file_name {File Name, defaults to 'unpaired_frequency.txt'}
             title {Optional Title, defaults to 'Unpaired Frequency'}

=cut

sub unpaired_frequency {
  my $self = shift;
  my %params = check_parameters (
    params   => \@_,
    type     => 'text',
    defaults => {
      file_name => 'unpaired_frequency.txt',
      title     => 'Unpaired Frequency',
    }
  );
  my %reads = $self->{pigeon_data}->reads (
    low         => $params{low},
    high        => $params{high},
    metagenomes => $params{metagenomes},
    sizes       => $params{sizes},
    extracted   => $params{extracted},
    layers      => $params{layers}
  );
  my ($counter, $total);
  foreach my $id (keys %reads) {
    if ( $reads{$id}{type} eq 'unpaired' &&
         $reads{$id}{bin} eq $params{bins}->[0] &&
         $reads{$reads{$id}{clone_pair}}{bin} eq $params{bins}->[1]
       ) {
      $counter ++;
    }
    if ($reads{$id}{bin} eq $params{bins}->[0] || $reads{$id}{bin} eq $params{bins}->[1]) {
      $total ++;
    }
  }
  createDirectory (fileName => $params{file_name});
  # Write output to file_name
  open (FILE, '>' . $params{file_name}) or die "Can't open for write: $!\n";
  print FILE $params{title} . "\n\n";
  print FILE 'Bin 0: ' . $self->{pigeon_data}->long_description(bin => $params{bins}->[0]) . "\n";
  print FILE 'Bin 1: ' . $self->{pigeon_data}->long_description(bin => $params{bins}->[1]) . "\n";
  printf FILE "Frequency: %.2f%%\n", $counter / $total * 100;
  close FILE;
}

=head2 random_reads

  Title    : random_reads
  Usage    : 
  Function : Randomly prints the specified number of reads for the given bin.
  Returns  : 
  Args     : bin {any of the valid bins}
             type {}
             number {number of reads to print}
             clone_pair {}

=cut

sub random_reads {
  my $self = shift;
  my %params = @_;
  my %reads = $self->{pigeon_data}->reads(%params);
  my @ids = ();
  # Create array of reads that match bin
  foreach my $id (keys %reads) {
    if ($reads{$id}{bin} eq $params{bin} && $reads{$id}{type} eq $params{type}) {
      if (defined $params{clone_pair} && $params{clone_pair} == 1) {
        @ids = (@ids, $id, $reads{$id}{clone_pair});
      }
      else {
        @ids = (@ids, $id);
      }
    }
  }
  # Randomly choose $number of reads from array with replacement and prints to the terminal
  for (my $i = 0; $i < $params{number}; $i ++) {
    my $j = int(rand(@ids));
    print "$ids[$j]\n";
  }
}

=head2 diff_meta_genome

  Title    : diff_meta_genome
  Usage    : 
  Function : Checks the metablast file against the metagenome file to see if they have the same reads.
  Returns  : 
  Args     : 

=cut

sub diff_meta_genome {
  my $self = shift;
  my %params = @_;
  my %reads = $self->{pigeon_data}->reads(%params);
  my $counter = 0;
  foreach my $id (keys %reads) {
    if (not defined $reads{$id}{sequence} || not defined $reads{$id}{bin}) {
      $counter ++;
    }
  }
  print "missing $counter\n";
}

=head2 hgt_events

  Title    : hgt_events
  Usage    : 
  Function : Creates a distance matrix of unpaired reads using the provided forced data files and test bins,
             reporting the number of reads, the average Nucleotide ID, and the delta NA ID for each combination.
  Returns  : 
  Args     : data_files {Array reference of forced data files}
             bins {Array reference of bins to test}

=cut

#sub hgt_events {
#  my $self = shift;
#  my %params = @_;
#  my %reads = $self->{pigeon_data}->reads(%params);
#  my @bins = @{$params{bins}};
#  my @data_bins;
#  my @average;
#  my @delta;
#  my @counter;

#  foreach my $file (@{$params{data_files}}) {
#    @data_bins = (@data_bins, $self->{pigeon_data}->add_forced_bins($file));
#  }
#  foreach my $bin (@data_bins) {
#    foreach my $id (keys %unpaired) {
#      for (my $i = 0; $i < @bins; $i++) {
#        for (my $j = 0; $j < @bins; $j++) {
#          if (defined $unpaired{$id}{forced}{$bin} && defined $unpaired{$id}{forced}{$bin} && (($unpaired{$id}{bin} eq $bins[$i] && $unpaired{$id}{bin} eq $bins[$j]) || ($unpaired{$id}{bin} eq $bins[$j] && $unpaired{$id}{bin} eq $bins[$i]))) {
#            $counter[$i][$j] ++;
#            $average[$i][$j] += ($unpaired{$id}{forced}{$bin}{percent_identity} + $unpaired{$id}{forced}{$bin}{percent_identity}) / 2;
#            $delta[$i][$j] += abs($unpaired{$id}{forced}{$bin}{percent_identity} - $unpaired{$id}{forced}{$bin}{percent_identity});
#          }
#        }
#      }
#    }
#    print "\t\t Metagenome vs. ", $self->{pigeon_data}->long_description(bin => $bin), "\n";
#    for (my $i = 0; $i < @bins; $i++) {
#      print "\t      ", $self->{pigeon_data}->short_description(bin => $bins[$i]), "     \t";
#    }
#    print "\n";
#    for (my $i = 0; $i < @bins; $i++) {
#      print $self->{pigeon_data}->short_description(bin => $bins[$i]), "\t";
#      for (my $j = 0; $j < @bins; $j++) {
#        if ($counter[$i][$j]) {
#          printf "(%4d, %2d%%, %2d%%)\t", $counter[$i][$j], $average[$i][$j] / $counter[$i][$j] * 100, $delta[$i][$j] / $counter[$i][$j] * 100;
#        }
#        else {
#          print "  ------------  \t";
#        }
#      }
#      print "\n";
#    }
#    print "\t\t(Count, Avg NA ID, Avg Delta NA ID)\n\n";
#  }
#}
#             

=head2 forced_syntenous_matrix

  Title    : forced_syntenous_matrix
  Usage    : 
  Function : Creates a matrix
  Returns  : 
  Args     : bins {Array reference of bins to test}
             forced_bins {Any of the valid forced bins}
             metagenome {mslow, mshigh, oslow, oshigh, low, high, total}
		mslow:	Mushroom Spring, low temperature
		mshigh: Mushroom Spring, high temperature
		oslow:	Octopus Spring, low temperature, 60*C
		oshigh: Octopus Spring, high temperature, 65*C
		ms:	Mushroom Spring, combined sample from both temperatures
		os:	Octopus Spring, combined sample from both temperatures
		low:	Low temperature, combined sample from both springs
		high:	High temperature, combined sample from both springs
		total:	Combined sample from both springs and both temperatures (default)
             size {2-3 kb, 3-4 kb, 4-5 kb, 5-6 kb, 8-9 kb, 10-12 kb, default total}
             extracted {TIGR, MSU, default total}
             layer {top 1mm, 1mm below top, bottom 1mm, default total}
             file_name {File Name, defaults to 'forced_genome_graph.gif'}
             title {Optional Title, caluclated from $params{metagenome} if not provided}

=cut

sub forced_syntenous_matrix {
  my $self = shift;
  my %params = check_parameters(
    params   => \@_,
    type     => 'text',
    defaults => {
      file_name   => 'forced_syntenous_matrix.txt',
      title       => 'Forced Syntenous Matrix',
      low         => 50,
      high        => 100
    }
  );
  my %reads = $self->{pigeon_data}->reads();
  my %forced = $self->{pigeon_data}->forced(%params);
  my (@syntenous_counter, @nonsyntenous_counter);
  # Initialize Arrays
  for (my $i = 0; $i < @{$params{bins}}; $i++) {
    for (my $j = 0; $j < @{$params{bins}}; $j++) {
      $syntenous_counter[$i][$j] = 0;
      $nonsyntenous_counter[$i][$j] = 0;
    }
  }
  foreach my $forced_bin (@{$params{forced_bins}}) {
    foreach my $id (keys %{$forced{$forced_bin}}) {
      for (my $i = 0; $i < @{$params{bins}}; $i++) {
        for (my $j = 0; $j < @{$params{bins}}; $j++) {
          if (
            $reads{$id}{clone_pair} ne 'null' && $reads{$id}{bin} eq ${$params{bins}}[$i] &&
            $reads{$reads{$id}{clone_pair}}{bin} eq ${$params{bins}}[$j]
          ) {
            if ($forced{$forced_bin}{$id}{type} eq 'paired_good_good') {
              $syntenous_counter[$i][$j] ++;
              if ($i ne $j) {
                $syntenous_counter[$j][$i] ++;
              }
            }
            elsif ($forced{$forced_bin}{$id}{type} =~ /^paired/ && $forced{$forced_bin}{$id}{type} ne 'paired_na') {
              $nonsyntenous_counter[$i][$j] ++;
              if ($i ne $j) {
                $nonsyntenous_counter[$j][$i] ++;
              }
            }
          }
        }
      }
    }
  }
  createDirectory (fileName => $params{file_name});
  # Write output to file_name
  open (FILE, '>' . $params{file_name}) or die "Can't open for write: $!\n";
  print FILE "\t", $params{title}, "\n";
  print FILE "\t\t";
  for (my $i = 0; $i < @{$params{bins}}; $i++) {
    print FILE $self->{pigeon_data}->short_description(bin => ${$params{bins}}[$i]), "\t\t";
  }
  print FILE "\n";
  for (my $j = 0; $j < @{$params{bins}}; $j++) {
    print FILE $self->{pigeon_data}->short_description(bin => ${$params{bins}}[$j]), "\tSyn\t";
    for (my $i = 0; $i < @{$params{bins}}; $i++) {
      if ($syntenous_counter[$i][$j] > 0) {
        printf FILE "(%6d %5.1f%%)\t", $syntenous_counter[$i][$j],
          $syntenous_counter[$i][$j] / ($syntenous_counter[$i][$j] + $nonsyntenous_counter[$i][$j]) * 100;
      }
      else {
        printf FILE "(%6d %5.1f%%)\t", 0, 0;
      }
    }
    print FILE "\n\tNon\t";
    for (my $i = 0; $i < @{$params{bins}}; $i++) {
      if ($nonsyntenous_counter[$i][$j] > 0) {
        printf FILE "(%6d %5.1f%%)\t", $nonsyntenous_counter[$i][$j],
          $nonsyntenous_counter[$i][$j] / ($syntenous_counter[$i][$j] + $nonsyntenous_counter[$i][$j]) * 100;
      }
      else {
        printf FILE "(%6d %5.1f%%)\t", 0, 0;
      }
    }    
    print FILE "\n";
  }
  print FILE "\t\t(Count,  Percent)\n";
  close (FILE);
}

=head2 psaA

  Title    : psaA 
  Usage    : 
  Function : 
  Returns  : 
  Args     : 

=cut

sub psaA {
  my $self = shift;
  my %params = @_;
  my %reads = $self->{pigeon_data}->reads(%params);

#  my ($psaA_file) = @_;
#  my @psaA_reads = $self->{pigeon_data}->get_file($psaA_file);
#  my $syntenous_counter = 0;
#  my $nonsyntenous_counter = 0;
#  my $unpaired_counter = 0;
#  my $nopair_counter = 0;
#  foreach my $line (@psaA_reads) {
#    my ($id, $score, $e_value) = split("\t", $line, 3);
#    my $paired_id = $id;
#    chop $paired_id;
#    if (defined $reads{$paired_id} && $reads{$paired_id}{type} eq 'paired_syntenous') {
#      print "$id syntenous with clone pair.\t\tScore: $score\tE-value: $e_value\n";
#      $syntenous_counter ++;
#    }
#    elsif (defined $reads{$paired_id}) {
#      print "$id non-syntenous with clone pair.\tScore: $score\tE-value: $e_value\n";
#      $nonsyntenous_counter ++;
#    }
#    elsif (defined $unpaired{$paired_id}) {
#      print "$id not paired with clone pair.\t\tScore: $score\tE-value: $e_value\n";
#      $unpaired_counter ++;
#    }
#    else {
#      print "$id has no clone pair.\t\t\tScore: $score\tE-value: $e_value\n";
#      $nopair_counter ++;
#    }
#  }
#  my $total = $syntenous_counter + $nonsyntenous_counter + $unpaired_counter + $nopair_counter;
#  print "\nSyntenous:\t$syntenous_counter\n";
#  print "Non-Syntenous:\t$nonsyntenous_counter\n";
#  print "Unpaired:\t$unpaired_counter\n";
#  print "No Pair:\t$nopair_counter\n";
#  print "Total:\t\t$total\n";
}

=head2 print_random_screened

  Title    : print_random_screened
  Usage    : 
  Function : Prints out number of reads with a %Nucleotide ID lower than cuttoff in FASTA format.
  Returns  : 
  Args     : cuttoff {Percent ID to use as a high cuttoff}
             number {Number of reads to print}

=cut

sub print_random_screened {
  my $self = shift;
  my %params = @_;
  my %reads = $self->{pigeon_data}->reads(%params);
  my @ids;

  foreach my $id (keys %reads) {
    if ($reads{$id}{percent_identity} < $params{cuttoff}) {
      push (@ids, $id);
    }
  }
  for (my $i = 0; $i < $params{number}; $i++) {
    my $j = int(rand(@ids));
    print ">$ids[$j]\n";
    print "$reads{$ids[$j]}{sequence}\n";
  }
}

=head2 print_fasta

  Title    : print_fasta
  Usage    : 
  Function : Prints out the reads in the provided bin, metagenome, size, extracted,
             and layer in FASTA format.  If provided, only reads with a Percent ID
             greater than or equal to the provided cuttoff will be displayed.
  Returns  : 
  Args     :  bin {any of the valid bins, default total}
              metagenome {mslow, mshigh, oslow, oshigh, low, high, default total}
		mslow:	Mushroom Spring, low temperature
		mshigh: Mushroom Spring, high temperature
		oslow:	Octopus Spring, low temperature, 60*C
		oshigh: Octopus Spring, high temperature, 65*C
		ms:	Mushroom Spring, combined sample from both temperatures
		os:	Octopus Spring, combined sample from both temperatures
		low:	Low temperature, combined sample from both springs
		high:	High temperature, combined sample from both springs
		total:	Combined sample from both springs and both temperatures
              size {2-3 kb, 3-4 kb, 4-5 kb, 5-6 kb, 8-9 kb, 10-12 kb, default total}
              extracted {TIGR, MSU, default total}
              layer {top 1mm, 1mm below top, bottom 1mm, default total}

=cut

sub print_fasta {
  my $self = shift;
  my %params = @_;
  my $fasta_width = 50;
  # Set default values for inputs.
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
  if (not defined $params{file_name}) {
   $params{file_name} = 'fasta';
  }
  my %reads = $self->{pigeon_data}->reads(%params);
  if (keys %reads > 0) {
    open (FILE, '>' . $params{file_name}) or die "Can't write to filea: $!\n";
    # Print FASTA
    foreach my $id (sort keys %reads) {
      my $length = length $reads{$id}{sequence};
      if (defined $reads{$id}{clone_id}) {
        print FILE ">gnl|$id|$reads{$id}{clone_id}"; 
      }
      else {
        print FILE ">gnl|$id|";
      }
      if (defined $reads{$id}{clone_pair} && $reads{$id}{clone_pair} ne 'null') {
        print FILE ' /mate=' . $reads{$id}{clone_pair};
      }
      print FILE ' /offset=0 /length=' . $length . ' /full_length=' . $length . "\n";
      for (my $i = 0; $i < $length / $fasta_width; $i ++) {
        print FILE substr($reads{$id}{sequence}, $i * $fasta_width, $fasta_width) . "\n";
      }
    }
    close FILE;
  }
}

=head2 print_cluster

  Title    : print_cluster
  Usage    : 
  Function : 
  Returns  : 
  Args     : k {}
             pca_name {}
             assembly_name {}
             file_name {}
             run {}

=cut

sub print_cluster {
  my $self = shift;
  my %params = @_;
  my $numDimensions = 10;
  my @range;
  if (not defined $params{run}) {
    $params{run} = 0;
  }
  ## Check if PCA-based, oligo-based, or 3D scatter-based clusters.  Read in array of hashes of cluster data.
  my (@clusters_pca, @clusters_oligo, @clusters_threeD);
  if (defined $params{oligo_name} ) {
    @clusters_oligo = $self->{pigeon_data}->clusters (
      k          => $params{k},
      oligo_name => $params{oligo_name}
    );
  }
  if (defined $params{pca_name}) {
    @clusters_pca = $self->{pigeon_data}->clusters (
      k        => $params{k},
      pca_name => $params{pca_name}
    );
  }
  if (defined $params{threeD_name}) {
    @clusters_threeD = $self->{pigeon_data}->clusters (
      k           => $params{k},
      threeD_name => $params{threeD_name}
    );


## once gmeans is working, we'll want to add the capability to exempt the k
## argument in clusters() calls.

#    if ($params{algorithm} eq 'gmeans') {
#      @clusters_threeD = $self->{pigeon_data}->clusters (
#        threeD_name => $params{threeD_name}
#      );
#    }




    my @error;
    # repeat cluster counts
    my @ids = sort $clusters_threeD[0]->ids();
    my $cluster_threeD;
    my (%data, @counter);
    for (my $i = 0; $i < @clusters_threeD; $i ++) {
      my (@cluster_list, %counter);
      push (@error, $clusters_threeD[$i]->error());
      foreach my $id (@ids) {
        if (@clusters_threeD) {
          $cluster_threeD = $clusters_threeD[$i];
        } 
        my $cluster = $clusters_threeD[$i]->cluster(id => $id);
        push (@{$cluster_list[$cluster]}, $id);
        $counter{$cluster} ++;
        # Count the number of clusters from this run.
        $counter[$i] = keys %counter;
        foreach my $list (@cluster_list) {
          foreach my $x (@{$list}) {
            foreach my $y (@{$list}) {
               $data{$x}{$y} ++;
            }
          }
        }
      }
    }
    # create cytoscape file for 3D data
    open (FILEC, '>' . $params{file_name} . '_cyto.txt') or die "Can't open for write: $!\n";
    foreach my $x (@ids) {
      foreach my $y (@ids) {
        if (defined $data{$x}{$y}) {
          if ($x eq $y) {
            next;
          }
          my $z = $data{$x}{$y} / @clusters_threeD;
          print FILEC "$x\t$y\tCoreCluster\t$z\n";
        }
      }  
    }
    close (FILEC);  


    # Create directory structure.
    createDirectory (fileName => $params{file_name});

    # Write output to 3D output_file
    open (FILE, '>' . $params{file_name}) or die "Can't open for write: $!\n";
    foreach my $i (@{$self->{pigeon_data}->{data}->{threeD}->{$params{threeD_name}}->{headers}} ) {
      print FILE $i, "\t";
    }
    print FILE 'cluster' . "\n";
    ## print bins
    my @keys = keys %{$self->{pigeon_data}->{data}->{threeD}->{$params{threeD_name}}->{threeD}};
    foreach my $key (@keys) {
      foreach my $i (@{$self->{pigeon_data}->{data}->{threeD}->{$params{threeD_name}}->{threeD}{$key}} ) {
        print FILE $i . "\t";
      }
      print FILE "cluster" . $cluster_threeD->cluster(id => $key) . "\n";
    }
    close (FILE);
  }
  elsif (defined $params{k} && defined $params{assembly_name} && defined $params{file_name}) {
    my $assembly = $self->{pigeon_data}->assembly (
      assembly_name => $params{assembly_name}
    );
    # Grab the correct cluster run
    my ($cluster_oligo, $cluster_pca);
    if (@clusters_oligo) {
      $cluster_oligo = $clusters_oligo[$params{run}];
    }
    if (@clusters_pca) {
      $cluster_pca = $clusters_pca[$params{run}];
    }
    # Create directory structure.
    createDirectory (fileName => $params{file_name});
    # Write output to output_file
    open (FILE, '>' . $params{file_name}) or die "Can't open for write: $!\n";
    print FILE "-\t";             # ID
    print FILE "5000\t";          # Fragment Size
    print FILE "999999999999\t";  # Contig Size
    # Print the dimensions.
    for (my $i = 1; $i <= $numDimensions; $i ++) {
      print FILE "dim$i\t";       # Dimensions
    }
    print FILE "User\t";
    print FILE "Cluster\t";       # Cluster Number
    print FILE "Phylo_Genes\n";   # Phylogenetic Genes of interest
    ## Case 1 - Both oligocount and PCA available for assemblies
    if ( (@clusters_pca) && (@clusters_oligo) ) {
      my @keys = $cluster_oligo->ids();
      foreach my $key (@keys) {
        my $vertex = $cluster_pca->vertex(id => $key);
        # print bins  
        print FILE $key . "\t";
        print FILE $assembly->size(id => $key) . "\t";
        print FILE $assembly->size(id => $key) . "\t";
        # Print each dimension of the vertex.
        for (my $i = 0; $i < $numDimensions; $i ++) {
          if (defined $vertex->[$i]) {
            print FILE $vertex->[$i] . "\t";
          }
          else {
            print FILE "0\t";
          }
        }
        print FILE "\t";
        print FILE "cluster" . $cluster_oligo->cluster(id => $key) . "\t";
        print FILE $assembly->gene(id => $key)."\n";
      }
    }
    ## Case 2 - Only PCA available for assemblies
    elsif ( (@clusters_pca) && not (@clusters_oligo) ) {
      my @keys = $cluster_pca->ids();
      foreach my $key (@keys) {
        my $vertex = $cluster_pca->vertex(id => $key);
        # print bins
        print FILE $key . "\t";
        print FILE $assembly->size(id => $key) . "\t";
        print FILE $assembly->size(id => $key) . "\t";
        for (my $i = 0; $i < $numDimensions; $i ++) {
          if (defined $vertex->[$i]) {
            print FILE $vertex->[$i] . "\t";
          }
          else {
            print FILE "0\t";
          }
        }
        print FILE "\t";
        print FILE "cluster" . $cluster_pca->cluster(id => $key) . "\t";
        print FILE $assembly->gene(id => $key) . "\n";
      }
    }
    elsif ( (@clusters_oligo) && not (@clusters_pca) ) {
      print "No 3D-plot data available - run PCA";
      return -1;
    }
    close FILE;
  }
}

=head2 print_cluster_summary

  Title    : cluster_summary
  Usage    : 
  Function : 
  Returns  : 
  Args     : bins {}
             k {}
             pca_name {}
             assembly_name {}
             file_name {}
             run {}

=cut

sub print_cluster_summary {
  my $self = shift;
  my %params = @_;
  my %reads;
  if (defined $params{reads}) {
    %reads = %{$params{reads}};
  }
  else {
    %reads = $self->{pigeon_data}->reads();
  }
  if (not defined $params{run}) {
    $params{run} = 0;
  }
  if (defined $params{bins} && defined $params{k} && (defined $params{pca_name} || defined $params{oligo_name}) &&
      defined $params{assembly_name} && defined $params{file_name}) {
    # Prefeably load oligo clusters if they exist, otherwise PCA.
    my @clusters;
    if (defined $params{oligo_name}) {
      @clusters = $self->{pigeon_data}->clusters (
        k        => $params{k},
        oligo_name => $params{oligo_name}
      );
    }
    else {
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
    # Count each cluster/bin combo.
    my @cluster_count;
    my @ntid;
    my @total_count;
    foreach my $key ($cluster->ids()) {
      foreach my $id ($assembly->reads(id => $key)) {
        if (defined $reads{$id}) {
          $cluster_count[$cluster->cluster(id => $key)]->{$reads{$id}{bin}} ++;
          $ntid[$cluster->cluster(id => $key)]->{$reads{$id}{bin}} += $reads{$id}{percent_identity};
          $total_count[$cluster->cluster(id => $key)] ++;
        }
      }
    }
    # Create directory structure.
    createDirectory (fileName => $params{file_name});
    # Open output file.
    open (FILE, '>' . $params{file_name}) or die "Can't open for write: $!\n";
    # Print Column Description
    print FILE "Cluster";
    foreach my $bin (@{$params{bins}}) {
      print FILE "\t\%";
      printf FILE '%-12s', $self->{pigeon_data}->short_description(bin => $bin);
    }
    print FILE "\n";
    # Print percentages for each cluster/bin combo.
    for (my $i = 0; $i < $params{k}; $i ++) {
      print FILE $i;
      foreach my $bin (@{$params{bins}}) {
        printf FILE "\t[%5.1f %5.1f]",
          defined $cluster_count[$i]->{$bin} ? $cluster_count[$i]->{$bin} / $total_count[$i] * 100 : 0,
          defined $ntid[$i]->{$bin} ? $ntid[$i]->{$bin} / $cluster_count[$i]->{$bin} : 0;
      }
      print FILE "\n";
#      printf FILE "%s", defined $total_count[$i] ? "Total reads: $total_count[$i]\n" : "$j\n";
    }
    close FILE;
  }
}

=head2 print_cluster_comparison

  Title    : print_cluster_comparison
  Usage    : $text->print_cluster_comparison(

             );
  Function : Prints
  Returns  : 
  Args     : k
             pca_name
             file_name
             assembly_name (OPTIONAL)

=cut

sub print_cluster_comparison {
  my $self = shift;
  my %params = @_;
  my $statistics = new Pigeon::Statistics ();
  my @error;
  if ( defined $params{k} and (defined $params{pca_name} || defined $params{oligo_name}) and defined $params{file_name} ) {
    # Preferably load oligo clusters if they exist, otherwise PCA.
    my @clusters;
    my $assembly;
    if ( defined $params{assembly_name} ) {
      $assembly = $self->{pigeon_data}->assembly (
        assembly_name => $params{assembly_name}
      );
    }
    if (defined $params{oligo_name}) {
      @clusters = $self->{pigeon_data}->clusters (
        k          => $params{k},
        oligo_name => $params{oligo_name}
      );
    }
    else {
      @clusters = $self->{pigeon_data}->clusters (
        k        => $params{k},
        pca_name => $params{pca_name}
      );
    }   
    my @ids = sort $clusters[0]->ids();
    my (%data, @counter);
    for (my $i = 0; $i < @clusters; $i ++) {
      my (@cluster_list, %counter);
      push (@error, $clusters[$i]->error());

      foreach my $id (@ids) {
        my $cluster = $clusters[$i]->cluster(id => $id);
        push (@{$cluster_list[$cluster]}, $id);
        $counter{$cluster} ++;
      }
      # Count the number of clusters from this run.
      $counter[$i] = keys %counter;
      foreach my $list (@cluster_list) {
        foreach my $x (@{$list}) {
          foreach my $y (@{$list}) {
            $data{$x}{$y} ++;
          }
        }
      }
    }
    # Create directory structure.
    createDirectory (fileName => $params{file_name});
    # Open output file.
    open (FILE, '>' . $params{file_name}) or die "Can't open for write: $!\n";
    # Print statistics.
    my $counter_ci = $statistics->confidence_interval (\@counter, 0.95);
    my $error_ci = $statistics->confidence_interval (\@error, 0.95);
    if (defined $params{oligo_name}) {
      printf FILE "Oligo_cluster: %s\n", $params{oligo_name};
    }
    else {
      printf FILE "PCA_cluster: %s\n", $params{pca_name};
    }
    printf FILE "K: %d\n", $params{k};
    printf FILE "N: %d\n\n", scalar @clusters;
    print  FILE "Number of clusters:\n";
    printf FILE "\tmin: %5.1f\n", $statistics->minimum (\@counter);
    printf FILE "\tmax: %5.1f\n", $statistics->maximum (\@counter);
    my $mean = $statistics->mean (\@counter);
    printf FILE "\tmean: %5.1f\n", $mean;
    printf FILE "\tstd dev: %5.1f\n", $statistics->standard_deviation (\@counter, $mean);
    printf FILE "\t95%% CI: (%5.1f, %5.1f)\n", $counter_ci->[0], $counter_ci->[1];
    print  FILE "Residual squared error distortion:\n";
    printf FILE "\tmin: %.3e\n", $statistics->minimum (\@error);
    printf FILE "\tmax: %.3e\n", $statistics->maximum (\@error);
    my $mean_error = $statistics->mean (\@error);
    printf FILE "\tmean: %.3e\n", $mean_error;
    printf FILE "\tstd dev: %.3e\n", $statistics->standard_deviation (\@error, $mean_error);
    printf FILE "\t95%% CI: (%.3e, %.3e)\n", $error_ci->[0], $error_ci->[1];
    close (FILE);

    ## Print matrix for importation into MCL, Cytoscape
    my $matrix_name = $params{file_name} . '_cyto.txt';
    open (FILEC, '>' . $matrix_name) or die "Can't open for write: $!, $matrix_name\n";
    # Print shared cluster frequency table
#    print FILE "\nShared cluster frequency:\n";
    # Print column titles.
#    printf FILE "%-15s\t", ' ';
#    foreach my $id (@ids) {
#      printf FILE "%-15s\t", $id;
#    }
#    print FILE "\n";
    # Print row titles and data.
    foreach my $x (@ids) {
#      printf FILEC "%-15s\t", $x;
      foreach my $y (@ids) {
#        printf FILE "%-7s%5.1f%%\t", $y, defined $data{$x}{$y} ? $data{$x}{$y} / @clusters *100 : 0;
        if (defined $data{$x}{$y}) {
          if ($x eq $y) {
            next;
          }
          my $z = $data{$x}{$y} / @clusters;
          print FILEC "$x\t$y\tCoreCluster\t$z";
        
#	else{
#          print FILEC "$x\t$y\t--\t--";
#        }
          my $phylogene;
          if (defined $params{assembly_name}) {
            $phylogene = $assembly->gene(id => $x) ;
            if (defined $phylogene && $phylogene !~ /\s+/ && $phylogene ne '') {
              print FILEC "\t$phylogene\n";
            }
            else {
	      print FILEC "\t-\n";
            }
          }
          
        }## FUTURE - Add in phylo-top BLAST hits?  MEGAN?
      }  
    }
    # Close output file.
    close FILEC;
  }
}

=head2 print_assembly

  Title    : print_assembly
  Usage    : 
  Function : 
  Returns  : 
  Args     : assembly_name {}
             file_name {}


=cut

sub print_assembly {
  my $self = shift;
  my %params = check_parameters (
    params   => \@_,
    type     => 'text',
    defaults => {
      file_name => 'assembly_summary.txt',
    }
  );
  my %reads = $self->{pigeon_data}->reads();
  my (%assembly, %ntid, %counter);
  if (defined $params{assembly_name}) {
    my $assembly = $self->{pigeon_data}->assembly (
      assembly_name => $params{assembly_name}
    );
    # Count each
    foreach my $key ($assembly->ids()) {
      foreach my $id ($assembly->reads(id => $key)) {
        if (defined $reads{$id}) {
          $assembly{$key}{$reads{$id}{bin}} ++;
          $ntid{$key}{$reads{$id}{bin}} += $reads{$id}{percent_identity};
          $counter{$key} ++;
        }
      }
    }
    # Create directory structure.
    createDirectory (fileName => $params{file_name});
    # Open output file.
    open (FILE, '>' . $params{file_name}) or die "Can't open for write: $!\n";
    # Print Column Description
    print FILE "Assembly";
    foreach my $bin (@{$params{bins}}) {
      print FILE "\t\%";
      printf FILE '%-8s', $self->{pigeon_data}->short_description(bin => $bin);
    }
    print FILE "\n";
    foreach my $key (keys %assembly) {
      print FILE $key;
      foreach my $bin (@{$params{bins}}) {
        printf FILE "\t[%5.1f %5.1f]",
          defined $assembly{$key}{$bin} ? $assembly{$key}{$bin} / $counter{$key} * 100 : 0,
          defined $ntid{$key}{$bin} ? $ntid{$key}{$bin} / $assembly{$key}{$bin} : 0;
      }
      print FILE "\n";
    }
    close FILE;
  }
}

=head2 clone_pair_t_test

  Title    : clone_pair_t_test
  Usage    :
  Function :
  Returns  :
  Args     : bin
             types
             significance
             file_name

=cut

sub clone_pair_t_test {
  my $self = shift;
  my %params = @_;
  my $statistics = new Pigeon::Statistics ();
  my %reads = $self->{pigeon_data}->reads();
  my (@paired, @unpaired, @syntenous, @nonsyntenous, $rejected, $p_value, $df, $t);
  foreach my $id (keys %reads) {
    if ($reads{$id}{bin} eq $params{bin}) {
      if ($reads{$id}{type} =~ /^paired/) {
        push (@paired, $reads{$id}{percent_identity});
        if ($reads{$id}{type} eq 'paired_good_good') {
          push (@syntenous, $reads{$id}{percent_identity});
        }
        elsif ($reads{$id}{type} ne 'paired_na') {
          push (@nonsyntenous, $reads{$id}{percent_identity});
        }
      }
      elsif ($reads{$id}{type} =~ /^unpaired/) {
        push (@unpaired, $reads{$id}{percent_identity});
      }
    }
  }
  # Create directory structure.
  createDirectory (fileName => $params{file_name});
  # Open output file.
  open (FILE, '>' . $params{file_name}) or die "Can't open for write: $!\n";
  print FILE $self->{pigeon_data}->long_description(bin => $params{bin}) . "\n\n";
  print FILE "Paired - Unpaired\n";
  printf FILE "Paired  \t%5.1f\t%5.1f\t%5.1f\t%5.1f\n", 
    $statistics->mean (\@paired),
    $statistics->standard_deviation (\@paired),
    $statistics->minimum (\@paired),
    $statistics->maximum (\@paired);
  printf FILE "Unpaired\t%5.1f\t%5.1f\t%5.1f\t%5.1f\n", 
     $statistics->mean (\@unpaired),
     $statistics->standard_deviation (\@unpaired),
     $statistics->minimum (\@unpaired),
     $statistics->maximum (\@unpaired);
  ($rejected, $p_value, $df, $t) = $statistics->t_test(\@paired, \@unpaired, $params{significance});
  if ($rejected == 1) {
    print FILE "T-test: reject null\ndf = $df\nt = $t\n";
  }
  elsif ($rejected == 0) {
    print FILE "T-test: fail to reject null\n"; 
  }
  else {
    print FILE "T-test: error\n";
  }
  print FILE "P-value: " . $p_value . "\n\n";
  print FILE "Syntenous - Non-Syntenous\n";
  printf FILE "Syntenous    \t%5.1f\t%5.1f\t%5.1f\t%5.1f\n",
    $statistics->mean (\@syntenous),
    $statistics->standard_deviation (\@syntenous),
    $statistics->minimum (\@syntenous),
    $statistics->maximum (\@syntenous);
  printf FILE "Non-Syntenous\t%5.1f\t%5.1f\t%5.1f\t%5.1f\n",
    $statistics->mean (\@nonsyntenous),
    $statistics->standard_deviation (\@nonsyntenous),
    $statistics->minimum (\@nonsyntenous),
    $statistics->maximum (\@nonsyntenous);
  ($rejected, $p_value, $df, $t) = $statistics->t_test(\@syntenous, \@nonsyntenous, $params{significance});
  if ($rejected == 1) {
    print FILE "T-test: reject null\ndf = $df\nt = $t\n";
  }
  elsif ($rejected == 0) {
    print FILE "T-test: fail to reject null\n"; 
  }
  else {
    print FILE "T-test: error\n";
  }
  print FILE "P-value: " . $p_value . "\n";
  close FILE;
}

=head2 forced_bin_t_test

  Title    : forced_bin_t_test
  Usage    :
  Function :
  Returns  :
  Args     : bins
             forced_bin
             significance
             file_name

=cut

sub forced_bin_t_test {
  my $self = shift;
  my %params = @_;
  my $statistics = new Pigeon::Statistics ();
  my %reads = $self->{pigeon_data}->reads();
  my %forced = $self->{pigeon_data}->forced(forced_bins => [$params{forced_bin}]);
  my (@bin0, @bin1, @syn0, @syn1, $rejected, $p_value, $df, $t);
  foreach my $id (keys %{$forced{$params{forced_bin}}}) {
    if ($reads{$id}{bin} eq $params{bins}->[0]) {
      push (@bin0, $forced{$params{forced_bin}}{$id}{percent_identity});
      if ($forced{$params{forced_bin}}{$id}{type} eq 'paired_good_good') {
        push (@syn0, $forced{$params{forced_bin}}{$id}{percent_identity});
      }
    }
    elsif ($reads{$id}{bin} eq $params{bins}->[1]) {
      push (@bin1, $forced{$params{forced_bin}}{$id}{percent_identity});
      if ($forced{$params{forced_bin}}{$id}{type} eq 'paired_good_good') {
        push (@syn1, $forced{$params{forced_bin}}{$id}{percent_identity});
      }
    }
  }
  # Create directory structure.
  createDirectory (fileName => $params{file_name});
  open (FILE, '>' . $params{file_name}) or die "Can't open for write: $!\n";

  print FILE "Forced Bin: " . $self->{pigeon_data}->long_description(bin => $params{forced_bin}) . "\n\n";
  print FILE "All reads\n";
  print FILE $self->{pigeon_data}->long_description(bin => $params{bins}->[0]) . "\t";
  printf FILE "%5.1f\t%5.1f\t%5.1f\t%5.1f\n",
    $statistics->mean (\@bin0),
    $statistics->standard_deviation (\@bin0),
    $statistics->minimum (\@bin0),
    $statistics->maximum (\@bin0);
  print FILE $self->{pigeon_data}->long_description(bin => $params{bins}->[1]) . "\t";
  printf FILE "%5.1f\t%5.1f\t%5.1f\t%5.1f\n",
    $statistics->mean (\@bin1),
    $statistics->standard_deviation (\@bin1),
    $statistics->minimum (\@bin1),
    $statistics->maximum (\@bin1);
  ($rejected, $p_value, $df, $t) = $statistics->t_test(\@bin0, \@bin1, $params{significance});
  if ($rejected == 1) {
    print FILE "T-test: reject null\ndf = $df\nt = $t\n";
  }
  elsif ($rejected == 0) {
    print FILE "T-test: fail to reject null\n"; 
  }
  else {
    print FILE "T-test: error\n";
  }
  print FILE "\n";
  print FILE "Syntenous reads\n";
  print FILE $self->{pigeon_data}->long_description(bin => $params{bins}->[0]) . "\t";
  printf FILE "%5.1f\t%5.1f\t%5.1f\t%5.1f\n",
    $statistics->mean (\@syn0),
    $statistics->standard_deviation (\@syn0),
    $statistics->minimum (\@syn0), maximum (\@syn0);
  print FILE $self->{pigeon_data}->long_description(bin => $params{bins}->[1]) . "\t";
  printf FILE "%5.1f\t%5.1f\t%5.1f\t%5.1f\n",
    $statistics->mean (\@syn1),
    $statistics->standard_deviation (\@syn1),
    $statistics->minimum (\@syn1),
    $statistics->maximum (\@syn1);
  ($rejected, $p_value, $df, $t) = $statistics->t_test(\@syn0, \@syn1, $params{significance});
  if ($rejected == 1) {
    print FILE "T-test: reject null\ndf = $df\nt = $t\n";
  }
  elsif ($rejected == 0) {
    print FILE "T-test: fail to reject null\n"; 
  }
  else {
    print FILE "T-test: error\n";
  }



  close FILE;
}

#=head2 genome_comparison_anova

#  Title    : genome_comparison_anova
#  Usage    :
#  Function :
#  Returns  :
#  Args     : genomes
#             file_name

#=cut

#sub genome_comparison_anova {
#  my $self = shift;
#  my %params = @_;
#  my %reads = $self->{pigeon_data}->reads();
#  my %data;
#  foreach my $genome (@{$params{genomes}}) {
#    my @data;
#    # Load metablast info.
#    open (GENOME, $genome->[0]) or die "Can't open file " . $genome->[0] . ": $!\n";
#    while (my $line = <GENOME>) {
#      chop $line;
#      ($_, $_, $_, $_, $_, my $bin, $_, $_, $_, $_, my $percent_id, $_) = split (/\t/, $line);
#      $bin = $self->{pigeon_data}->parse_bin(bin => $bin);
#      if ($bin ne 'null') {
#        push (@data, $percent_id);
#      }
#    }
#    close(GENOME);
#    $data{$genome->[1]} = \@data;
#  }

#  open (FILE, '>' . $params{file_name}) or die "Can't open for write: $!\n";

#  print FILE "ntid\tgenome\n";
#  foreach my $genome (keys %data) {
#    foreach my $ntid (@{$data{$genome}}) {
#      print FILE "$ntid\t$genome\n";
#    }
#  }

#  close FILE;

#  anova (%data);

#}

=head2 tiled_genome_data

  Title    : tiled_genome_data
  Usage    : $graph->tiled_genome_data(
               bins => ['syna'],
               file_name => 'tiled_genome_data.txt'
             );
  Function : Creates a Tiled Genome Data file for the provided bins, etc.
  Args     : file_name: File name, defaults to 'tiled_genome_data.txt'
             titles: Title of this file
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

=cut

sub tiled_genome_data {
  my $self = shift;
  my %params = check_parameters (
    params   => \@_,
    type     => 'text',
    defaults => {
      alpha           => 0.05,
      file_name       => 'tiled_genome_data.txt',
      titles          => ['Tiled Genome Data']
    }
  );
  my %reads = $self->{pigeon_data}->reads(%params);
  my $genome_size = 0;
  # Grab largest genome from bins
  foreach my $bin (@{$params{bins}}) {
    if ($self->{pigeon_data}->genome_size(bin => $bin) > $genome_size) {
      $genome_size = $self->{pigeon_data}->genome_size(bin => $bin);
    }
  }
  # Create directory structure.
  createDirectory (fileName => $params{file_name});
  open (FILE, '>' . $params{file_name}) or die "Can't open for write: $!\n";
  # Print titles.
  foreach my $title (@{$params{titles}}) {
    print FILE $title . "\n";
  }
  print FILE "\n";
  # Print column headers.
  print FILE "ID\tSource\tStart\tStop\tIdentity\tStrand\tsequencer_plate_barcode\tRunID\tWellCoordinates\t96WellQuadrant\t96WellCoordinates\n";
  # Gather and output data.
  my $y_value = 0;
  foreach my $category (@{$params{categories}}) {
    my @used;
    foreach my $id (sort_by_location %reads) {
      if (test_categories(item => $reads{$id}{type}, list => [$category]) && 
          not contains(item => $id, list => \@used)) {
        push @used, $reads{$id}{clone_pair};
        print FILE $id;
        print FILE "\t" . $reads{$id}{source};
        print FILE "\t" . $reads{$id}{subject_start};
        print FILE "\t" . $reads{$id}{subject_end};
        print FILE "\t" . $reads{$id}{percent_identity};
        print FILE "\t" . $reads{$id}{query_strand};
        print FILE "\t";
        print FILE $reads{$id}{definitions}{sequencer_plate_barcode} if (defined $reads{$id}{definitions}{sequencer_run_id});
        print FILE "\t";
        print FILE $reads{$id}{definitions}{sequencer_run_id} if (defined $reads{$id}{definitions}{sequencer_run_id});
        print FILE "\t";
        print FILE $reads{$id}{definitions}{sequencer_plate_well_coordinates} if (defined $reads{$id}{definitions}{sequencer_plate_well_coordinates});
        print FILE "\t";
        print FILE $reads{$id}{definitions}{sequencer_plate_96well_quadrant} if (defined $reads{$id}{definitions}{sequencer_plate_96well_quadrant});
        print FILE "\t";
        print FILE $reads{$id}{definitions}{sequencer_plate_96well_coordinates} if (defined $reads{$id}{definitions}{sequencer_plate_96well_coordinates});
        print FILE "\n";

        if (defined $reads{$id}{clone_pair} && defined $reads{$reads{$id}{clone_pair}}) {
          print FILE $reads{$id}{clone_pair};
          print FILE "\t" . $reads{$reads{$id}{clone_pair}}{source};
          print FILE "\t" . $reads{$reads{$id}{clone_pair}}{subject_start};
          print FILE "\t" . $reads{$reads{$id}{clone_pair}}{subject_end};
          print FILE "\t" . $reads{$reads{$id}{clone_pair}}{percent_identity};
          print FILE "\t" . $reads{$reads{$id}{clone_pair}}{query_strand};
          print FILE "\t";
          print FILE $reads{$reads{$id}{clone_pair}}{definitions}{sequencer_plate_barcode} if (defined $reads{$reads{$id}{clone_pair}}{definitions}{sequencer_run_id});
          print FILE "\t";
          print FILE $reads{$reads{$id}{clone_pair}}{definitions}{sequencer_run_id} if (defined $reads{$reads{$id}{clone_pair}}{definitions}{sequencer_run_id});
          print FILE "\t";
          print FILE $reads{$reads{$id}{clone_pair}}{definitions}{sequencer_plate_well_coordinates} if (defined $reads{$reads{$id}{clone_pair}}{definitions}{sequencer_plate_well_coordinates});
          print FILE "\t";
          print FILE $reads{$reads{$id}{clone_pair}}{definitions}{sequencer_plate_96well_quadrant} if (defined $reads{$reads{$id}{clone_pair}}{definitions}{sequencer_plate_96well_quadrant});
          print FILE "\t";
          print FILE $reads{$reads{$id}{clone_pair}}{definitions}{sequencer_plate_96well_coordinates} if (defined $reads{$reads{$id}{clone_pair}}{definitions}{sequencer_plate_96well_coordinates});
          print FILE "\n";
        }
        print FILE "\n";      

      }
    }
  }
  close FILE;
}

=head2 synteny_binomial_test

  Title    : synteny_binomial_test
  Usage    : $text->rrna_16s_binomial_test (
               alpha           => 0.05,
               probability     => 0.50,
               method          => 'two.sided',
               bins            => ['syna'], 
               metagenomes     => ['mush68'],
               sizes           => ['total'],
               extracted       => ['total'],
               layers          => ['total'],
               categories      => ['total'],
               file_name       => 'synteny_binomial_test.txt',
               titles          => ['Synteny Binomial Test']
             );
  Function : Counts the number of syntenous and non-syntenous read pairs that meet
             the requirements specified by the parameters.  Uses an exact binomial
             test to test the hypothesis that there is equal probability of getting
             syntenous vs. a non-syntenous read.  Prints out a table of the
             statistics for the given parameters to the specified file_name.
  Args     : alpha       - Alpha value to use for binomial test, defaults to 0.05.
             probability - The hypothesized probability to to use for the binomial test, defaults to 0.50.
             method      - Method to use ['two.sided', 'less', 'greater'], defaults to 'two.sided'.
             file_name   - File name, defaults to 'synteny_binomial_test.txt'
             titles      - Array reference of titles to print in this file
             bins        - Array reference of valid bins to include, defaults to total.
             lows        - Array reference of low percent_id values for each bin, defaults to 0 for all bins.
             highs       - Array reference of high percent_id values for each bin, defaults to 100 for all bins.
             metagenomes - Array reference of valid metagenomes to include, defaults to total.
             sizes       - Array reference containing valid sizes, defaults to total.
             extracted   - Array reference of valid extracted to include, defaults to total.
             layers      - Array reference of valid layers to include, defaults to total.
             categories  - Array reference of categories to include, defaults to total.
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

sub synteny_binomial_test {
  my $self = shift;
  my %params = check_parameters (
    params   => \@_,
    type     => 'text',
    defaults => {
      alpha       => 0.05,
      probability => 0.50,
      method      => 'two.sided',
      file_name   => 'synteny_binomial_test.txt',
      titles      => ['Synteny Binomial Test']
    }
  );
  my $statistics = new Pigeon::Statistics ();
  my %reads = $self->{pigeon_data}->reads(%params);

  # Grab the number of syntenous reads.
  my $syntenous = 0;
  my $nonsyntenous = 0;
  foreach my $id (keys %reads) {
    if (test_categories(item => $reads{$id}{type}, list => ['paired_syntenous'])) {
      $syntenous ++;
    }
    elsif (test_categories(item => $reads{$id}{type}, list => ['paired_nonsyntenous'])) {
      $nonsyntenous ++;
    }
  }
  # Run a binomial test on the sytenous/non-sytenous counts.
  my $conf_level = 1 - $params{alpha};
  my ($estimate, $ci, $pvalue) = $statistics->binomial_test (
    $syntenous, 
    $syntenous + $nonsyntenous, 
    $params{probability},
    $conf_level,
    $params{method}
  );
  # Create directory structure.
  createDirectory (fileName => $params{file_name});
  open (FILE, '>' . $params{file_name}) or die "Can't open for write: $!\n";
  # Print titles.
  foreach my $title (@{$params{titles}}) {
    print FILE $title . "\n";
  }
  print FILE "\n";
  # Output the statistics.  
  print FILE "Number of syntenous reads: " . $syntenous . "\n";
  print FILE "Number of non-syntenous reads: " . $nonsyntenous . "\n";
  print FILE "\n";
  print FILE "Hypothesized probability of receiving a syntenous read: " . $params{probability} . "\n";
  print FILE "Estimated probability of receiving a syntenous read: " . $estimate . "\n";
  print FILE ($conf_level * 100) . "% confidence interval: " . $ci . "\n";
  print FILE "P-value: " . $pvalue . "\n";
  print FILE "\n";
  if ($pvalue < $params{alpha}) {
    print FILE "Reject the null hypothesis.\n";
  }
  else {
    print FILE "Fail to reject the null hypothesis.\n";
  }
  close FILE;
}

=head2 rrna_16s_binomial_test

  Title    : rrna_16s_binomial_test
  Usage    : $text->rrna_16s_binomial_test (
               alpha           => 0.05,
               probability     => 0.50,
               method          => 'two.sided',
               bins            => ['syna'], 
               metagenomes     => ['mush68'],
               sizes           => ['total'],
               extracted       => ['total'],
               layers          => ['total'],
               categories      => ['total'],
               rrna_16s        => [1110781, 2310964],
               file_name       => 'rrna_16s_binomial_test.txt',
               titles          => ['16S rRNA Binomial Test']
             );
  Function : Counts the number of read pairs that meet the requirements specified
             by the parameters, and who ends span and fall within 100kb of the two
             provided 16S rRNA locations.  Uses an exact binomial test to test the
             hypothesis that there is equal probability of getting a spanning read
             versus a read that doesn't span the 16S rRNA locations.  Prints out a
             table of the statistics for the given parameters to the specified 
             file_name.
  Args     : alpha       - Alpha value to use for binomial test, defaults to 0.05.
             probability - The hypothesized probability to to use for the binomial test, defaults to 0.50.
             method      - Method to use ['two.sided', 'less', 'greater'], defaults to 'two.sided'.
             file_name   - File name, defaults to 'rrna_16s_binomial_test.txt'
             titles      - Array reference of titles to print in this file
             bins        - Array reference of valid bins to include, defaults to total.
             lows        - Array reference of low percent_id values for each bin, defaults to 0 for all bins.
             highs       - Array reference of high percent_id values for each bin, defaults to 100 for all bins.
             metagenomes - Array reference of valid metagenomes to include, defaults to total.
             sizes       - Array reference containing valid sizes, defaults to total.
             extracted   - Array reference of valid extracted to include, defaults to total.
             layers      - Array reference of valid layers to include, defaults to total.
             categories  - Array reference of categories to include, defaults to total.
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

sub rrna_16s_binomial_test {
  my $self = shift;
  my %params = check_parameters (
    params   => \@_,
    type     => 'text',
    defaults => {
      alpha       => 0.05,
      probability => 0.50,
      method      => 'two.sided',
      file_name   => 'rrna_16s_binomial_test.txt',
      titles      => ['16S rRNA Binomial Test']
    }
  );
  my $statistics = new Pigeon::Statistics ();
  my %reads = $self->{pigeon_data}->reads(%params);
  # Define the size of the error bar.
  my $error = 100000;
  # Grab the number of reads that span the two 16S rRNA locations.
  my $span = 0;
  my $dont_span = 0;
  foreach my $id (keys %reads) {
    if (defined $reads{$id}{clone_pair} && defined $reads{$reads{$id}{clone_pair}}) {
      my ($start, $stop);
      if ($reads{$id}{subject_start} < $reads{$reads{$id}{clone_pair}}{subject_start}) {
        $start = $reads{$id}{subject_start};
        $stop = $reads{$reads{$id}{clone_pair}}{subject_end};
      }
      else {
        $start = $reads{$reads{$id}{clone_pair}}{subject_start};
        $stop = $reads{$id}{subject_end};
      }
      if (
        $start > $params{rrna_16s}->[0] - $error &&
        $start < $params{rrna_16s}->[0] + $error &&
        $stop > $params{rrna_16s}->[1] - $error &&
        $stop < $params{rrna_16s}->[1] + $error
      ) {
        $span ++;
      }
      else {
        $dont_span ++;
      }
    }
  }
  # Run a binomial test on the span/not-spaned counts.
  my $conf_level = 1 - $params{alpha};
  my ($estimate, $ci, $pvalue) = $statistics->binomial_test (
    $span, 
    $span + $dont_span, 
    $params{probability},
    $conf_level,
    $params{method}
  );
  # Create directory structure.
  createDirectory (fileName => $params{file_name});
  open (FILE, '>' . $params{file_name}) or die "Can't open for write: $!\n";
  # Print titles.
  foreach my $title (@{$params{titles}}) {
    print FILE $title . "\n";
  }
  print FILE "\n";
  # Output the statistics.  
  print FILE "Number of reads that span the two 16S rRNA locations: " . $span . "\n";
  print FILE "Number of reads that do not span the two 16S rRNA locations: " . $dont_span . "\n";
  print FILE "\n";
  print FILE "Hypothesized probability of receiving a spanned read: " . $params{probability} . "\n";
  print FILE "Estimated probability of receiving a spanned read: " . $estimate . "\n";
  print FILE ($conf_level * 100) . "% confidence interval: " . $ci . "\n";
  print FILE "P-value: " . $pvalue . "\n";
  print FILE "\n";
  if ($pvalue < $params{alpha}) {
    print FILE "Reject the null hypothesis.\n";
  }
  else {
    print FILE "Fail to reject the null hypothesis.\n";
  }
  close FILE;
}

=head2 rrna_16s_range_test

  Title    : rrna_16s_range_test
  Usage    : $text->rrna_16s_range_test (
               bins            => ['syna'], 
               metagenomes     => ['mush68'],
               sizes           => ['total'],
               extracted       => ['total'],
               layers          => ['total'],
               categories      => ['total'],
               rrna_16s        => [1110781, 2310964],
               file_name       => 'rrna_16s_range_test.txt',
               titles          => ['16S rRNA Range Test']
             );
  Function : Counts the number of syntenous & non-syntenous reads that meet the requirements specified
             by the parameters, and that are within 100kb of provided 16S rRNA locations.  Prints, to
             the provided file_name, a table of the syntenous/non-syntenous counts at each 16S rRNA location.
  Args     : file_name   - File name, defaults to 'rrna_16s_range_test.txt'
             titles      - Array reference of titles to print in this file.
             bins        - Array reference of valid bins to include, defaults to total.
             lows        - Array reference of low percent_id values for each bin, defaults to 0 for all bins.
             highs       - Array reference of high percent_id values for each bin, defaults to 100 for all bins.
             metagenomes - Array reference of valid metagenomes to include, defaults to total.
             sizes       - Array reference containing valid sizes, defaults to total.
             extracted   - Array reference of valid extracted to include, defaults to total.
             layers      - Array reference of valid layers to include, defaults to total.
             categories  - Array reference of categories to include, defaults to total.
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

sub rrna_16s_range_test {
  my $self = shift;
  my %params = check_parameters (
    params   => \@_,
    type     => 'text',
    defaults => {
      file_name => 'rrna_16s_range_test.txt',
      titles    => ['16S rRNA Range Test']
    }
  );
  my %reads = $self->{pigeon_data}->reads(%params);
  # Define the size of the error bar.
  my $error = 100000;
  # Grab the number of reads that are within the range of the two 16S rRNA locations.
  my @syntenous;
  my @nonsyntenous;
  for (my $i = 0; $i < @{$params{rrna_16s}}; $i ++) {
    $syntenous[$i] = 0;
    $nonsyntenous[$i] = 0;
    my $start = $params{rrna_16s}->[$i] - $error;
    my $stop = $params{rrna_16s}->[$i] + $error;
    foreach my $id (keys %reads) {
      if (
        ($reads{$id}{subject_start} > $start && $reads{$id}{subject_start} < $stop) ||
        ($reads{$id}{subject_end} > $start && $reads{$id}{subject_end} < $stop)
      ) {
        if (test_categories(item => $reads{$id}{type}, list => ['paired_syntenous'])) {
          $syntenous[$i] ++;
        }
        elsif (test_categories(item => $reads{$id}{type}, list => ['paired_nonsyntenous'])) {
          $nonsyntenous[$i] ++;
        }
      }
    }
  }
  # Create directory structure.
  createDirectory (fileName => $params{file_name});
  open (FILE, '>' . $params{file_name}) or die "Can't open for write: $!\n";
  # Print titles.
  foreach my $title (@{$params{titles}}) {
    print FILE $title . "\n";
  }
  print FILE "\n";
  for (my $i = 0; $i < @{$params{rrna_16s}}; $i ++) {
    print FILE "16S rRNA Location: " . $params{rrna_16s}->[$i] . "\n";
    print FILE "Syntenous: " . $syntenous[$i] . "\n";
    print FILE "Non-Syntenous: " . $nonsyntenous[$i] . "\n";
    print FILE "Total Reads: " . ($syntenous[$i] + $nonsyntenous[$i]) . "\n";
    print FILE "\n";
  }
  close FILE;
}

sub _check_range {
  my ($value, $start, $stop) = @_;
  my $within_range = 0;
  if (($value > $start) && ($value < $stop)) {
    $within_range = 1;
  }
  return $within_range;
}


1;
__END__


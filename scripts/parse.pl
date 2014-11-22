#!/usr/bin/perl

use strict;
use warnings;

use Bio::SearchIO;
use IO::File;

my ($file, $top_hits) = @ARGV;
my ($fh, $format, $searchIO);

## Check command line argument.
if (@ARGV == 0) {
  print "Usage: $0 <Blast file> <Number of top hits>\n";
  exit 1;
}

# Set default values.
if (not defined $top_hits) {
  $top_hits = 1;
}

# Create new filehandle for the Blast file.
$fh = IO::File->new($file) or die "Can't open file " . $file . ": $!\n";

# Determine the format of the Blast file.
if (<$fh> =~ /<?xml/) {
  $format = 'blastxml';
}
else {
  $format = 'blast';
}

# Reset the filehandle.
seek $fh, 0, 0;

# Load the Blast file.
$searchIO = new Bio::SearchIO(-fh => $fh, -format => $format);

# Read in data.
my %results;
while (my $result = $searchIO->next_result()) {
  while (my $hit = $result->next_hit()) {
    while (my $hsp = $hit->next_hsp()) {
      # Grab the important result, hit, and hsp data from Bio::SearchIO.
      my %hit = (
        query_description   => $result->query_description,
        query_accession     => $result->query_accession,
        query_length        => $result->query_length,
        database_name       => $result->database_name,
        database_letters    => $result->database_letters,
        database_entries    => $result->database_entries,
        algorithm           => $result->algorithm,
        algorithm_version   => $result->algorithm_version,
        name                => $hit->name,
        description         => $hit->description,
        accession           => $hit->accession,
        locus               => $hit->locus,
        length              => $hit->length,
        n                   => $hit->n,
        score               => $hsp->score,
        start_query         => $hsp->start('query'),
        end_query           => $hsp->end('query'),
        start_subject       => $hsp->start('sbjct'),
        end_subject         => $hsp->end('sbjct'),
        percent_identity    => $hsp->percent_identity,
        fraction_conserved  => $hsp->frac_conserved,
        fraction_identical  => $hsp->frac_identical,
        number_identical    => $hsp->num_identical,
        number_conserved    => $hsp->num_conserved,
        gaps                => $hsp->gaps,
        significance        => $hsp->significance,
        bits                => $hsp->bits,
        rank                => $hsp->rank,
        strand_query        => $hsp->strand('query'),
        strand_subject      => $hsp->strand('sbjct'),
        e_value             => $hsp->evalue
      );
      # Push data into results hash, sort it, and keep only the first $top_hits in memory.
      push (@{$results{$result->query_name}}, \%hit);
      @{$results{$result->query_name}} = sort {$b->{score} <=> $a->{score}} @{$results{$result->query_name}};
      if ($top_hits < @{$results{$result->query_name}}) {
        @{$results{$result->query_name}} = splice (@{$results{$result->query_name}}, 0, $top_hits);
      }
    }
  }
  if (not defined $results{$result->query_name}) {
    # Found a null result.  Grab available information and set required defaults.
    my %hit = (
      query_description   => $result->query_description,
      query_accession     => $result->query_accession,
      query_length        => $result->query_length,
      algorithm           => $result->algorithm,
      algorithm_version   => $result->algorithm_version,
      database_name       => $result->database_name,
      database_letters    => $result->database_letters,
      database_entries    => $result->database_entries,
      name                => 'null',
      description         => '',
      accession           => '',
      locus               => '',
      length              => '',
      n                   => '',
      score               => 0,
      start_query         => '',
      end_query           => '',
      start_subject       => '',
      end_subject         => '',
      percent_identity    => '',
      fraction_conserved  => '',
      fraction_identical  => '',
      number_identical    => '',
      number_conserved    => '',
      gaps                => '',
      significance        => '',
      bits                => '',
      rank                => '',
      strand_query        => '',
      strand_subject      => '',
      e_value             => ''
    );
    # Push data into results hash.
    push (@{$results{$result->query_name}}, \%hit);
  }
}
# Print tab-delimited output.
foreach my $id (keys %results) {
  for (my $i = 0; $i < @{$results{$id}}; $i ++) {
    print $id, "\t",                                      # query name
          $results{$id}->[$i]{query_description}, "\t",   # query description
          $results{$id}->[$i]{query_length}, "\t",        # query length
          $results{$id}->[$i]{algorithm}, "\t",           # algorithm
          $results{$id}->[$i]{database_name}, "\t",       # database
          $results{$id}->[$i]{name}, "\t",                # bin
          $results{$id}->[$i]{description}, "\t",         # description
          $results{$id}->[$i]{start_query}, "\t",         # start_query
          $results{$id}->[$i]{end_query}, "\t",           # stop_query
          $results{$id}->[$i]{start_subject}, "\t",       # start_subject
          $results{$id}->[$i]{end_subject}, "\t",         # stop_subject
          $results{$id}->[$i]{percent_identity}, "\t",    # percent_id
          $results{$id}->[$i]{fraction_conserved}, "\t",  # percent_similarity
          $results{$id}->[$i]{score}, "\t",               # score
          "\t\t\t\t",
          $results{$id}->[$i]{strand_query}, "\t",        # strand_query
          $results{$id}->[$i]{strand_subject}, "\t",      # strand_subject
          $results{$id}->[$i]{e_value}, "\t\n";           # e_value
  }
}

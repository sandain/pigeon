=head1 NAME

  Pigeon::Fasta

=head1 SYNOPSIS

  An object used to create, load, and save Fasta formatted files.

=head1 DESCRIPTION

  This package creates a Pigeon::Fasta object to handle Fasta formated data.

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

  Copyright (C) 2010  Jason Wood, Montana State University

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

package Pigeon::Fasta;

use strict;
use warnings;

use Pigeon::Tools qw (:all);

## Private Methods.

my $parseSequenceHeader = sub {
  my $self = shift;
  my $header = join ' ', @_;
  my $meta;
  # Split the identifier and description strings of the new sequence.
  my ($identifier, $description) = split (/\s+/, $header, 2);
  # Search for meta information in the description string.
  if (defined $description) {
    foreach my $d (split (/\s+/, $description)) {
      if ($d =~ /[\\|\/]?(\S+)=(\S+)/) {
        $meta->{$1} = $2;
      }
    }
    $meta->{description} = $description;
  }
  # The default identifier is the one supplied.
  $meta->{identifier} = lc $identifier;
  # Search for meta information in the identifier string.
  if ($identifier =~ /^gnl\|([^\|]+\|?(.*))/) {
    $meta->{identifier} = lc $1;
    $meta->{contig} = $2 if $2 ne '';
  }
  elsif ($identifier =~ /^gi\|([^\|]+)\|(gb|emb|dbj|ref)\|([^\|]+)\|(.*)/) {
    $meta->{gi} = $1;
    $meta->{accession} = $3;
    $meta->{contig} = $4 if $4 ne '';
  }
  elsif ($identifier =~ /^(gb|emb|dbj|ref)\|([^\|]+)\|(.*)/) {
    $meta->{accession} = $2;
    $meta->{contig} = $3 if $3 ne '';
  }
  return $meta;
};

# Add a sequence to this Fasta object.
my $addSequence = sub {
  my $self = shift;
  my %params = @_;
  # Add the sequence to the hash if its identifier and sequence have lengths greater than 0.
  my $idLength = length $params{identifier};
  my $seqLength = length $params{sequence};
  if ($idLength > 0 && $seqLength > 0 && not defined $self->{sequence}{$params{identifier}}) {
    $self->{sequence}{$params{identifier}} = {
      identifier  => $params{identifier},
      description => $params{description},
      sequence    => $params{sequence},
      mate        => $params{mate},
      meta        => $params{meta},
      order       => $self->{lastIndex},
      length      => $seqLength
    };
    # Find the length of the longest and shortest sequences.
    if ($seqLength > $self->{maxLength}) {
      $self->{maxLength} = $seqLength;
    }
    if ($seqLength < $self->{minLength} || $self->{minLength} == 0) {
      $self->{minLength} = $seqLength;
    }
    $self->{lastIndex} ++;
  }
};

# Load a Fasta formated file.
my $loadFasta = sub {
  my $self = shift;
  my @fasta = @_;
  my @sequenceHeaders;
  my $sequence = '';
  foreach my $line (@fasta) {
    # Remove end-of-line characters.
    $line =~ s/\s*[\n|\r]+//g;
    # Check to see if this line contains the start of a sequence or header.
    # If so, save the previous sequence data if it exists.
    if ($line =~ /^[>|;]/ or $line =~ /^\s*#/) {
      if (@sequenceHeaders > 0 && $sequence ne '') {
        my $meta = $self->$parseSequenceHeader (@sequenceHeaders);
        $self->$addSequence (
          identifier  => $meta->{identifier},
          description => $meta->{description},
          sequence    => lc $sequence,
          mate        => $meta->{mate},
          meta        => $meta
        );
        # Clear the header and sequence variables to get ready for the next sequence.
        @sequenceHeaders = ();
        $sequence = '';
      }
    }
    # Parse through the new header or sequence data.
    if ($line =~ /^\s*\#\s*[\\|\/]\s*(\w+)=(\w+)/) {
      # Line contains file header info.
      push @{$self->{header}}, {
        key   => $1,
        value => $2,
        order => $self->{lastIndex}
      };
      $self->{lastIndex} ++;
    }
    elsif ($line =~ /^[>|;]/) {
      # Line contains sequence header info.
      $line =~ s/^[>|;]\s*//g;
      push @sequenceHeaders, $line;
    }
    else {
      # Line contains sequence data.
      $sequence .= $line;
    }
  }
  # Add the last sequence data to the object.
  if (@sequenceHeaders > 0 && $sequence ne '') {
    my $meta = $self->$parseSequenceHeader (@sequenceHeaders);
    $self->$addSequence (
      identifier  => $meta->{identifier},
      description => $meta->{description},
      sequence    => lc $sequence,
      mate        => $meta->{mate},
      meta        => $meta
    );
  }
};

## Public Methods.

=head2 new

  Title    : new
  Usage    : my $fasta = new Pigeon::Fasta (
               fileName => 'sequences.fa'
             );
             $fasta->add (
               identifier  => 'newSeq1',
               sequence    => 'acgtttccattaccaca',
               description => 'mate=newSeq2 date=MMDDYYYY'
             );
             $fasta->add (
               identifier  => 'newSeq2',
               sequence    => 'tttcactggaagctgca',
               description => 'mate=newSeq1 date=MMDDYYYY'
             );
             $fasta->save (
               fileName => 'newSequences.fa'
             );
  Function : Creates a new Pigeon::Fasta object.
  Returns  : The new Pigeon::Fasta object.
  Args     : fileName - The path and file name of the Fasta formatted file to load.
             fh       - The file handle of the Fasta formatted file to load.

=cut

sub new {
  my $invocant = shift;
  my %params = @_;
  my $class = ref ($invocant) || $invocant;
  my $self = {
    header    => undef,
    sequence  => undef,
    lastIndex => 0,
    minLength => 0,
    maxLength => 0
  };
  bless $self => $class;
  if (defined $params{fileName} && -e $params{fileName}) {
    my $fh = loadFile ($params{fileName});
    $self->$loadFasta (<$fh>);
    close $fh;
  }
  elsif (defined $params{fh}) {
    $self->$loadFasta (<$params{fh}>);
  }
  elsif (defined $params{fasta}) {
    $self->$loadFasta (@{$params{fasta}});
  }
  return $self;
}

=head2 add

  Title    : add
  Usage    : $fasta->add(fileName => 'sequences.fa');
  Function : Add a Fasta formatted file, or sequence data to this object.
  Args     : fileName    - If supplied, adds this Fasta formated file to this object.
             fh          - If supplied, adds this file handle to a Fasta formated file to this object.
             fasta       - If supplied, adds this array reference of Fasta formated data to this object.
             identifier  - If supplied, adds this identifier to this object.
             description - If supplied, adds this description to this object.
             sequence    - If supplied, adds this sequence to this object.

=cut

sub add {
  my $self = shift;
  my %params = @_;
  if (defined $params{fileName} && -e $params{fileName}) {
    my $fh = loadFile ($params{fileName});
    $self->$loadFasta (<$fh>);
    close $fh;
  }
  if (defined $params{fh}) {
    $self->$loadFasta (<$params{fh}>);
  }
  elsif (defined $params{fasta}) {
    $self->$loadFasta (@{$params{fasta}});
  }
  else {
    $self->$addSequence (
      identifier  => lc $params{identifier},
      description => $params{description},
      sequence    => lc $params{sequence} 
    );
  }
}

=head2 addHeader

  Title    : addHeader
  Usage    : $fasta->addHeader(key => 'newHeader', value => 'newValue');
  Function : Adds the supplied header to this object.
  Args     : key   -
             value -

=cut

sub addHeader {
  my $self = shift;
  my %params = @_;
  if (defined $params{key} && defined $params{value}) {
    push @{$self->{header}}, {
      key   => $params{key},
      value => $params{value},
      order => $self->{lastIndex}
    };
    $self->{lastIndex} ++;
  } 
}

=head2 get

  Title    : get
  Usage    : my $seq = $fasta->get(identifier => 'seq1');
             print '>' . $seq->{identifier} . "\n";
             print $seq->{sequence} . "\n";
  Function : Returns the sequence data of the supplied identifier.
  Return   : The sequence data of the supplied identifier.
  Args     : identifier  - Returns the sequence hash with the given identifier.

=cut

sub get {
  my $self = shift;
  my %params = @_;
  my $seq;
  my $identifier = lc $params{identifier};
  if (length $identifier > 0 && defined $self->{sequence}{$identifier}) {
    $seq = $self->{sequence}{$identifier};
  }
  return $seq;
}

=head2 getAll

  Title    : getAll
  Usage    : my @seqs = $fasta->getAll();
             foreach my $seq (@seqs) {
               print '>' . $seq->{identifier} . "\n";
               print $seq->{sequence} . "\n";
             }
  Function : Returns all of the sequence data in this object as an array.
  Return   : The array of sequence data contained in this object.

=cut

sub getAll {
  my $self = shift;
  my @all;
  if (defined $self->{sequence}) {
    @all = sort {$a->{order} <=> $b->{order}} values %{$self->{sequence}};
  }
  return @all;
}

=head2 getIdentifiers

  Title    : getIdentifiers
  Usage    : my @ids = $fasta->getIdentifiers();
             foreach my $id (@ids) {
               print #/' . $id . "\n";
             }
  Function : Returns all of the identifiers in this object as an array.
  Return   : The array of identifiers contained in this object.

=cut

sub getIdentifiers {
  my $self = shift;
  my @ids;
  if (defined $self->{sequence}) {
    @ids = keys %{$self->{sequence}};
  }
  return @ids;
}

=head2 getHeaders

  Title    : getHeaders
  Usage    : my @headers = $fasta->getHeaders();
             foreach my $header (@headers) {
               print #/' . $header->{key} . "=" . $header->{value} . "\n";
             }
  Function : Returns all of the headers in this object as an array.
  Return   : The array of headers contained in this object.

=cut

sub getHeaders {
  my $self = shift;
  my @headers;
  if (defined $self->{header}) {
    @headers = @{$self->{header}};
  }
  return @headers;
}

=head2 remove

  Title    : remove
  Usage    : 
  Function : Removes the sequence hash with the given identifier.
  Args     : identifier  - Removes the sequence hash with the given identifier.

=cut

sub remove {
  my $self = shift;
  my %params = @_;
  my $identifier = lc $params{identifier};
  if (length $identifier > 0 && defined $self->{sequence}{$identifier}) {
    delete $self->{sequence}{$identifier};
  }
}

=head2 save

  Title    : save
  Usage    : $fasta->save(fileName => 'newSequences.fa');
  Function : Saves the sequence data stored in this object to a Fasta formated file.
  Args     : fileName    - The file name to save the Fasta data to.
             printHeader - Boolean value, 1 to print the header data, default 0.
             width       - Width of the sequence to print per line, defaults to printing the entire sequence on one line.

=cut

sub save {
  my $self = shift;
  my %params = @_;
  if (defined $params{fileName}) {
    # Make sure that the directory structure is in place.
    createDirectory (fileName => $params{fileName});
    # Open the fasta file with write permission.
    open FASTA, '>' . $params{fileName} or die "Error: Can't write to file " . $params{fileName} . ": $!\n";
    # Print out each header and sequence in the appropriate order.
    my @fasta = values %{$self->{sequence}};
    push @fasta, @{$self->{header}} if ($params{printHeader});
    foreach my $line (sort {$a->{order} <=> $b->{order}} (@fasta)) {
      if (defined $line->{key}) {
        # Line contains header data.
        print FASTA '#\\' . $line->{key} . '=' . $line->{value} . "\n";
      }
      else {
        # Line contains sequence data.
        my $width = length $line->{sequence};
        $width = $params{width} if (defined $params{width});
        print FASTA '>' . $line->{identifier};
        print FASTA ' ' . $line->{description} if (defined $line->{description});
        print FASTA "\n";
        for (my $i = 0; $i < length $line->{sequence}; $i += $width) {
          my $seq = substr ($line->{sequence}, $i, $width);
          print FASTA $seq . "\n";
        }
      }
    }
    close FASTA;
  }
}

=head2 set

  Title    : set
  Usage    : $fasta->set (identifier => 'seq1', description => 'type=a');
  Function :
  Args     : identifier  - Modifies the sequence hash with the given identifier.
             description - If supplied, sets the description of this sequence hash.
             sequence    - If supplied, sets the sequence to this sequence hash.

=cut

sub set {
  my $self = shift;
  my %params = @_;
  my $meta = $self->$parseSequenceHeader ($params{identifier}, $params{description});

  if (defined $meta->{identifier} && length $meta->{identifier} > 0 && defined $self->{sequence}{$meta->{identifier}}) {

    if (defined $params{description} ) {
      $self->{sequence}{$meta->{identifier}}{description} = $params{description};
      $self->{sequence}{$meta->{identifier}}{mate} = $meta->{mate};
      $self->{sequence}{$meta->{identifier}}{meta} = $meta;
    }
    if (defined $params{sequence}) {
      $self->{sequence}{$meta->{identifier}}{sequence} = lc $params{sequence};
    }
  }
}

=head2 maxLength

  Title    : maxLength
  Usage    : $fasta->maxLength()
  Function : Retuns the length of the longest sequence in this Fasta.
  Return   : The length of the longest sequence.

=cut

sub maxLength {
  my $self = shift;
  return $self->{maxLength};
}

=head2 minLength

  Title    : minLength
  Usage    : $fasta->minLength()
  Function : Retuns the length of the shortest sequence in this Fasta.
  Return   : The length of the shortest sequence.

=cut

sub minLength {
  my $self = shift;
   return $self->{minLength};
}

=head2 size

  Title    : size
  Usage    : $fasta->size()
  Function : Returns the number of sequences stored in this Fasta.
  Return   : The number of sequences.

=cut

sub size {
  my $self = shift;
  return scalar keys %{$self->{sequence}};
}

1;
__END__


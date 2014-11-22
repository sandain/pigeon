=head1 NAME

  Pigeon - A tool for metagenome analysis.

=head1 SYNOPSIS


=head1 DESCRIPTION

  This package is used for initializing Pigeon.

=head1 DEPENDENCIES

  Pigeon requires Perl version 5.6.1 or greater, in addition
  to the following packages:
    BioPerl >= 1.006
    File::Temp >= 0.22
    GD >= 2.39
    GD::Graph >= 1.44
    Image::Magick >= 6.5.0
    IO::Uncompress::Gunzip >= 2.00
    List::Util >= 1.21
    POSIX >= 1.13

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

package Pigeon;

use strict;
use warnings;

our $TITLE = 'Pigeon';
our $VERSION = '0.2.0';

1;
__END__

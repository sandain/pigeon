=head1 NAME

  Pigeon::Statistics

=head1 SYNOPSIS

  Private usage by Pigeon.

=head1 DESCRIPTION

  This package holds Statistics methods used in various modules of the Pigeon package.

=head1 DEPENDENCIES

  This package depends on the R Statistical package.

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

package Pigeon::Statistics;

use strict;
use warnings;

use File::Temp;
use List::Util qw(shuffle);
use List::MoreUtils qw(uniq);


my $MAX_LENGTH = 50,
my $SUPPRESS_WARNINGS = 1;
my $SUPPRESS_PACKAGE_STARTUP_MESSAGES = 1;

## Private Methods.

my $R = sub {
  my $self = shift;
  my ($script) = @_;
  # Create a temporary file.
  my $fh = new File::Temp ();
  my $fname = $fh->filename;
  # Write the script to the temporary file.
  print $fh $script;
  # Close the temporary file.
  $fh->close;
  # Run R on the script, saving the output in an array.
  my @output = `xvfb-run -a R --slave --vanilla < $fname`;
  # Read the output from R.
  my %vars;
  my $event;
  foreach my $line (@output) {
    # Look for recognized output events.
    if ($line =~ /PIGEON:(\w+)/) {
      $event = $1;
    }
    elsif (defined $event) {
      $vars{$event} .= $line;
    }
  }
  return %vars;
};

my $convert1dArray = sub {
  my $self = shift;
  my ($variable, $data) = @_;
  # Don't try to parse empty data.
  return if (not defined $data);
  # Grab the dimension of the data.
  my $n = @{$data};
  # Convert the data.
  my $script = $variable . ' <- c(';
  for (my $i = 0; $i < $n; $i ++) {
    $script .= $data->[$i];
    if ($i < $n - 1) {
      $script .= ",";
      $script .= "\n" if ($i % $MAX_LENGTH == $MAX_LENGTH - 1);
    }
  }
  $script .= ")\n";
  return $script;
};

my $convert2dArray = sub {
  my $self = shift;
  my ($variable, $data, $rownames, $colnames) = @_;
  # Don't try to parse empty data.
  return if (not defined $data);
  # Grab the dimensions of the data.
  my $n = @{$data};
  my $m = @{$data->[0]};
  # Convert the data.
  my $script = $variable . ' <- c(';
  for (my $j = 0; $j < $m; $j ++) {
    for (my $i = 0; $i < $n; $i ++) {
      $script .= $data->[$i][$j];
      $script .= "," if (($i + 1) * ($j + 1) < $n * $m);
      $script .= "\n" if ((($j * $n) + $i) % $MAX_LENGTH == $MAX_LENGTH - 1);
    }
  }
  $script .= ")\n";
  # Add dimensions to the data.
  $script .= "dim($variable) <- c($n, $m)\n";
  # Add row and column names to the data.
  if (defined $rownames) {
    $script .= $self->$convert1dArray ("rownames($variable)", $rownames);
  }
  if (defined $colnames) {
    $script .= $self->$convert1dArray ("colnames($variable)", $colnames);
  }
  return $script;
};

my $loadRlibrary = sub {
  my $self = shift;
  my ($library) = @_;
  my $script = "library($library)";
  if ($SUPPRESS_WARNINGS) {
    $script = "suppressWarnings($script)" if ($SUPPRESS_WARNINGS);
  }
  if ($SUPPRESS_PACKAGE_STARTUP_MESSAGES) {
    $script = "suppressPackageStartupMessages($script)";
  }
  return $script . "\n";
};

## Public Methods.

=head2 new

  Title    : new
  Usage    : 
  Function : Creates a new Pigeon::Statistics object
  Returns  : New Pigeon::Statistics object

=cut

sub new {
  my $invocant = shift;
  my %params = @_;
  my $class = ref ($invocant) || $invocant;
  my $self = {};
  bless $self => $class;
  return $self;
}

=head2 minimum

  Title     : minimum
  Usage     : my $min = minimum([1,2,3,4,5,6,7,8,9,10]);
  Function  : Returns the minimum value in the provided list.
  Returns   : min - Minimum value from list.
  Args      : array - Array reference of numbers.

=cut

sub minimum {
  my $self = shift;
  my ($array) = @_;
  my $min;
  if (@{$array} > 0) {
    my @sorted = sort {$a <=> $b} @{$array};
    $min = $sorted[0];
  }
  return $min;
}

=head2 maximum

  Title     : maximum
  Usage     : my $max = maximum([1,2,3,4,5,6,7,8,9,10]);
  Function  : Returns the maximum value in the provided list.
  Returns   : max - Maximum value from list.
  Args      : array - Array reference of numbers.

=cut

sub maximum {
  my $self = shift;
  my ($array) = @_;
  my $max;
  if (@{$array} > 0) {
    my @sorted = sort {$b <=> $a} @{$array};
    $max = $sorted[0];
  }
  return $max;
}

=head2 mean

  Title     : mean
  Usage     : my $mean = mean([1,2,3,4,5,6,7,8,9,10]);
  Function  : Returns the mean of a list.
  Returns   : mean - Mean of the given list.
  Args      : array - Array reference of numbers.

=cut

sub mean {
  my $self = shift;
  my ($array) = @_;
  my $mean = 0;
  if (@{$array} > 0) {
    my $sum = 0;
    foreach my $item (@{$array}) {
      $sum += $item;
    }
    $mean = $sum / @{$array};
  }
  return $mean;
}

=head2 median

  Title     : median
  Usage     : my $median = median([1,2,3,4,5,6,7,8,9,10]);
  Function  : Returns the median of the given list.
  Returns   : median - Median of the given list.
  Args      : array - Array reference of numbers

=cut

sub median {
  my $self = shift;
  my ($array) = @_;
  my $median = 0;
  if (@{$array} > 0) {
    my @sorted = sort @{$array};
    $median = $sorted[round(@sorted / 2)];
  }
  return $median;
}

=head2 standard_deviation

  Title     : standard_deviation
  Usage     : my $stdev = standard_deviation([1,2,3,4,5,6,7,8,9,10]);
  Function  : Returns the standard deviation of the given list.
  Returns   : sdev - Standard deviation of the given list.
  Args      : array - Array reference of numbers
              mean  - Optional mean of the array

=cut

sub standard_deviation {
  my $self = shift;
  my ($array, $mean) = @_;
  my $sdev = 0;
  if (@{$array} > 0) {
    if (not defined $mean) {
      $mean = mean ($array);
    }
    my $sumsq = 0;
    foreach my $item (@{$array}) {
      $sumsq += ($item - $mean) ** 2;
    }
    $sdev = sqrt ($sumsq / (@{$array} - 1));
  }
  return $sdev;
}

=head2 confidence_interval

  Title     : confidence_interval
  Usage     : my $ci = confidence_interval ([1,2,3,4,5,6,7,8,9,10]);
  Function  : Returns the confidence interval of the given list as an array reference.
  Returns   : ci - Array reference to the confidence interval of the given list.
  Args      : array        - Array reference of numbers.
              significance - Significance level to use for this confidence interval, defaults to 0.95.
              mean         - Optional mean of the array

=cut

sub confidence_interval {
  my $self = shift;
  my ($array, $significance, $mean) = @_;
  my $ci = [0, 0];
  if (not defined $significance) {
    $significance = 0.95;
  }
  if (@{$array} > 0) {
    if (not defined $mean) {
      $mean = $self->mean ($array);
    }
    my $n = @{$array};
    my $df = $n - 1;
    my $stdev = $self->standard_deviation ($array, $mean);
    # Create the script to send to R.
    my $script = "t <- qt($significance, df=$df)\n";
    $script .= "print('PIGEON:t')\n";
    $script .= "print(t)\n";
    $script .= "q()\n";
    # Run the script.
    my %vars = $self->$R ($script);
    # Convert t.
    $vars{t} = "" if (not defined $vars{t});
    $vars{t} =~ s/[\s\r\n]//g;
    $vars{t} =~ s/\[\d+\]//g;
    # Calculate the delta.
    my $delta = $vars{t} * $stdev / sqrt $n;
    $ci = [$mean - $delta, $mean + $delta];
  }
  return $ci;
}

=head2 pca

  Title     : pca
  Usage     :  my $statistics = new Pigeon::Statistics ();
               my $data = [[10, 10, 10],
                          [10, 10, 50],
                          [10, 50, 10],
                          [10, 50, 50],
                          [50, 10, 10],
                          [50, 10, 50],
                          [50, 50, 10],
                          [50, 50, 50]];
              my ($sdev, $rotation, $scores, $center, $scale) = $statistics->pca ($data);
  Function  : Performs a Principal Components Analysis using R on the provided data.
  Returns   : sdev     - Array reference to the standard deviation for each component.
              rotation - Array reference to the rotation.
              scores   - Array reference to the scores.
              center   - Array reference to the center.
              scale    - Array reference to scale to the scale
  Args      : x - Array reference to a 2d array to perform the analysis on.

=cut

sub pca {
  my $self = shift;
  my ($x) = @_;
  my (@sdev, @rotation, @scores, @center, @scale);
  # Create the script to send to R.
  my $maxPrint = @{$x} * @{$x->[0]};
  my $script = "options(max.print=$maxPrint)\n";
  $script .=  $self->$convert2dArray ('x', $x);
  $script .= "p <- prcomp(x)\n";
  $script .= "print('PIGEON:sdev')\n";
  $script .= "print(p\$sdev)\n";
  $script .= "print('PIGEON:rotation')\n";
  $script .= "print(p\$rotation)\n";
  $script .= "print('PIGEON:scores')\n";
  $script .= "print(p\$x)\n";
  $script .= "print('PIGEON:center')\n";
  $script .= "print(p\$center)\n";
  $script .= "print('PIGEON:scale')\n";
  $script .= "print(p\$scale)\n";
  $script .= 'q()' . "\n";
  # Run the script.
  my %vars = $self->$R ($script);
  # Convert sdev.
  $vars{sdev} = "" if (not defined $vars{sdev});
  $vars{sdev} =~ s/[\r\n]//g;
  $vars{sdev} =~ s/\s*\[\d+\]//g;
  $vars{sdev} =~ s/^\s+//;
  @sdev = split /\s+/, $vars{sdev};
  # Convert rotation.
  $vars{rotation} = "" if (not defined $vars{rotation});
  $vars{rotation} =~ s/\s+PC\d+//g;
  foreach my $r (split /\n/, $vars{rotation}) {
    if ($r =~ /\s*\[(\d+),\]/) {
      my $i = $1 - 1;
      $r =~ s/\s*\[\d+,\]//;
      $r =~ s/^\s+//;
      push @{$rotation[$i]}, split /\s+/, $r;
    }
  }
  # Convert scores.
  $vars{scores} = "" if (not defined $vars{scores});
  $vars{scores} =~ s/\s+PC\d+//g;
  foreach my $s (split /\n/, $vars{scores}) {
    if ($s =~ /\s*\[(\d+),\]/) {
      my $i = $1 - 1;
      $s =~ s/\s*\[\d+,\]//;
      $s =~ s/^\s+//;
      push @{$scores[$i]}, split /\s+/, $s;
    }
  }
  # Convert center.
  $vars{center} = "" if (not defined $vars{center});
  $vars{center} =~ s/[\r\n]//g;
  $vars{center} =~ s/\s*\[\d+\]//g;
  $vars{center} =~ s/^\s+//;
  @center = split /\s+/, $vars{center};
  # Convert scale.
  $vars{scale} = "" if (not defined $vars{scale});
  $vars{scale} =~ s/[\r\n]//g;
  $vars{scale} =~ s/\s*\[\d+\]//g;
  $vars{scale} =~ s/^\s+//;
  @scale = split /\s+/, $vars{scale};
  return (\@sdev, \@rotation, \@scores, \@center, \@scale);
}

=head2 shapiro_wilk

  Title     : shapiro_wilk
  Usage     : my $alpha = 0.05;
              my $data = [1, 1, 1, 2, 2, 3, 2, 2, 1, 1, 1];
              my ($test, $statistic, $pvalue) = shapiro_wilk($data, $alpha);
  Function  : Performs the Shapiro-Wilk test of normality on the provided data using R.
  Returns   : test      - 1 if normal, 0 if not normal.
              statistic - The W statistic returned from the test.
              pvalue    - The P Value returned from the test.
  Args      : x     - Array reference to the data to test.
              alpha - The alpha level to use for the test.

=cut

sub shapiro_wilk {
  my $self = shift;
  my ($x, $alpha) = @_;
  # Verify that there are 3-5000 elements in the data.
  if (@{$x} < 3) {
    die "Error: Can't run the Shapiro-Wilk test with less than 3 elements!\n";
  }
  if (@{$x} > 5000) {
    my @temp = shuffle (@{$x});
    @{$x} = @temp[0..4999];
  }
  # Create the script to send to R.
  my $script = $self->$convert1dArray ('x', $x);
  $script .= 'sw <- shapiro.test(x)' . "\n";
  $script .= "print('PIGEON:statistic')\n";
  $script .= 'print(sw$statistic)' . "\n";
  $script .= "print('PIGEON:pvalue')\n";
  $script .= 'print(sw$p.value)' . "\n";
  $script .= 'q()' . "\n";
  # Run the script.
  my %vars = $self->$R ($script);
  # Convert statistic.
  $vars{statistic} = "" if (not defined $vars{statistic});
  $vars{statistic} =~ s/[W\s\r\n]//g;
  # Convert pvalue.
  $vars{pvalue} = "" if (not defined $vars{pvalue});
  $vars{pvalue} =~ s/[\s\r\n]//g;
  $vars{pvalue} =~ s/\[\d+\]//;
  # Check if the data is normal.
  my $test = 0;
  if ($vars{pvalue} >= $alpha) {
    $test = 1;
  }
  return ($test, $vars{statistic}, $vars{pvalue});
}

=head2 g_test

  Title     : g_test
  Usage     : my $data = [
                [1, 1, 1, 2, 2, 3, 2, 2, 1, 1, 1],
                [3, 4, 3, 5, 4, 5, 3, 3, 2, 3, 1]
              ];
              my ($statistic, $pvalue, $df) = g_test($data);
  Function  : Performs the Likelihood Ratio (G test) for contingency tables using R.
  Returns   : statistic - The G statistic returned from the test.
              pvalue    - The P Value returned from the test.
              df        - The degrees of freedom from the test.
  Args      : x - Array reference to the data to test.

=cut

sub g_test {
  my $self = shift;
  my ($x) = @_;
  # Create the script to send to R.
  my $script = $self->$loadRlibrary ("Deducer");
  $script .= $self->$convert2dArray ('x', $x);
  $script .= "gt <- likelihood.test(x, conservative=FALSE)\n";
  $script .= "print('PIGEON:statistic')\n";
  $script .= 'print(gt$statistic)' . "\n";
  $script .= "print('PIGEON:pvalue')\n";
  $script .= 'print(gt$p.value)' . "\n";
  $script .= "print('PIGEON:df')\n";
  $script .= 'print(gt$parameter)' . "\n";
  $script .= 'q()' . "\n";
  # Run the script.
  my %vars = $self->$R ($script);
  # Cleanup the returned values.
  $vars{statistic} = "" if (not defined $vars{statistic});
  $vars{statistic} =~ s/Log likelihood ratio statistic \(G\)//g;
  $vars{statistic} =~ s/[\s\r\n]+//g;
  $vars{pvalue} = "" if (not defined $vars{pvalue});
  $vars{pvalue} =~ s/p.value//g;
  $vars{pvalue} =~ s/[\s\r\n]+//g;
  $vars{df} = "" if (not defined $vars{df});
  $vars{df} =~ s/X-squared df//g;
  $vars{df} =~ s/[\s\r\n]+//g;
  return ($vars{statistic}, $vars{pvalue}, $vars{df});
}

=head2 t_test

  Title     : t_test
  Usage     :
  Function  : Performs the student's t-test using R.
  Returns   : reject    - 1 if the null hypothesis is rejected, 0 if the null hypothesis is not rejected}
              statistic - The statistic returned by R.
              df        - The degrees of freedom returned by R.
              pvalue    - The pvalue returned by R.
  Args      : x              - Array reference to the first sample.
              y              - Array reference to the second sample.
              method         - less, greater, two.sided, defaults to two.sided.
              equal_variance - 0 if not equal, 1 if equal, defaults to not equal.
              significance   - Significance level to use in this t test, defaults to 0.95.

=cut

sub t_test {
  my $self = shift;
  my ($x, $y, $method, $equal_variance, $significance) = @_;
  # Set default method.
  if (not defined $method) {
    $method = 'two.sided';
  }
  # Set default equal_variance.
  if (defined $equal_variance && $equal_variance == 1) {
    $equal_variance = 'TRUE';
  }
  else {
    $equal_variance = 'FALSE';
  }
  # Set the default significance.
  if (not defined $significance) {
    $significance = 0.95;
  }
  my $alpha = (1 - $significance) / 2;
  # Create the script to send to R.
  my $script = $self->$convert1dArray ('x', $x);
  $script .= $self->$convert1dArray ('y', $y);
  $script .= "t <- t.test(x,y,alternative=$method,var.equal=$equal_variance,conf.level=$significance)\n";
  $script .= "print('PIGEON:statistic')\n";
  $script .= "print(t\$statistic)\n";
  $script .= "print('PIGEON:df')\n";
  $script .= "print(t\$parameter)\n";
  $script .= "print('PIGEON:pvalue')\n";
  $script .= "print(t\$p.value)\n";
  $script .= "q()\n";
  # Run the script.
  my %vars = $self->$R ($script);
  # Convert statistic.
  $vars{statistic} = "" if (not defined $vars{statistic});
  $vars{statistic} =~ s/[t\s\r\n]//g;
  # Convert df.
  $vars{df} = "" if (not defined $vars{df});
  $vars{df} =~ s/[df\s\r\n]//g;
  # Convert pvalue.
  $vars{pvalue} = "" if (not defined $vars{pvalue});
  $vars{pvalue} =~ s/[\s\r\n]//g;
  $vars{pvalue} =~ s/\[\d+\]//;
  # Test the null hypothesis.
  my $reject = 0;
  if ($vars{pvalue} < $alpha) {
    # Reject the null hypothesis.
    $reject = 1;
  }
  return ($reject, $vars{statistic}, $vars{df}, $vars{pvalue});
}

=head2 binomial_test

  Title    : binomial_test
  Usage    : my $successes = 5000;
             my $trials = 10000;
             my $probability = 1 / 2;
             my $significance = 0.95;
             my $method = 'two.sided';
             my ($estimate, $ci, $pvalue) = binomial_test(
               $successes,
               $trials,
               $probability,
               $significance,
               $method
             );
  Function : Performs an exact binomial test using R.
  Returns  : The estimated probability of success, confidence interval, and p-value.
  Args     : x            - The number of successes.
             n            - The number of trials.
             p            - The hypothesized probability of success.
             method       - Method to use {'two.sided', 'less', 'greater'}, defaults to 'two.sided'.
             significance - The significance level to use for the binomial test, defaults to 0.95.

=cut

sub binomial_test {
  my $self = shift;
  my ($x, $n, $p, $method, $significance) = @_;
  # Set default method.
  if (not defined $method) {
    $method = 'two.sided';
  }
  # Set the default significance.
  if (not defined $significance) {
    $significance = 0.95;
  }
  # Create the script to send to R.
  my $script = "b <- binom.test($x,$n,$p,alternative=$method,conf.level=$significance)\n";
  $script .= "print('PIGEON:estimate')\n";
  $script .= "print(b\$estimate)\n";
  $script .= "print('PIGEON:ci')\n";
  $script .= "print(b\$conf.int)\n";
  $script .= "print('PIGEON:pvalue')\n";
  $script .= "print(b\$p.value)\n";
  # Run the script.
  my %vars = $self->$R ($script);
  # Convert estimate.
  $vars{estimate} = "" if (not defined $vars{estimate});
  $vars{estimate} =~ s/^[a-zA-Z\s]+//;
  $vars{estimate} =~ s/[\s\r\n]//g;
  # Convert ci.
  $vars{ci} = "" if (not defined $vars{ci});
  ($vars{ci}) = split /[\r\n]+/, $vars{ci};
  $vars{ci} =~ s/\s*\[\d+\]\s+//;
  # Convert pvalue.
  $vars{pvalue} = "" if (not defined $vars{pvalue});
  $vars{pvalue} =~ s/[\r\n]//g;
  $vars{pvalue} =~ s/\s*\[\d+\]\s+//;
  return ($vars{estimate}, $vars{ci}, $vars{pvalue});
}

=head2 fisher_test

  Title    : fisher_test
  Usage    : 
  Function : Performs a Fisher's exact test using R.
  Returns  : 
  Args     : x            - Array reference to the data to test.
             method       - less, greater, two.sided, defaults to two.sided.
             significance - Significance level to use in this t test, defaults to 0.95.

=cut

sub fisher_test {
  my $self = shift;
  my ($x, $method, $significance) = @_;

  # Set default method.
  if (not defined $method) {
    $method = 'two.sided';
  }
  # Set the default significance.
  if (not defined $significance) {
    $significance = 0.95;
  }
  # Create the script to send to R.
  my $script = $self->$convert2dArray ('x', $x);
  $script .= "f <- fisher.test(x,alternative=$method,conf.level= $significance)\n";
  $script .= "print('PIGEON:pvalue')\n";
  $script .= "print(f\$p.value)\n";
  $script .= "q()\n";
  # Run the script.
  my %vars = $self->$R ($script);
  $vars{pvalue} = "" if (not defined $vars{pvalue});
  return ($vars{pvalue});
}

=head2

  Title    : cca
  Usage    : 
  Function : Performs a Canonical Correspondence Analysis using the R vegan
             package.
  Returns  : 
  Args     : 

=cut

sub cca {
  my $self = shift;
  my (
    $file,
    $communityMatrix, $constrainingMatrix, $conditioningMatrix,
    $sampleNames, $communityNames, $constrainingNames, $conditioningNames,
    $sampleCategories, $communityCategories,
    $sampleColors, $communityColors
  ) = @_;
  # Create the script to send to R.
  my $script = $self->$loadRlibrary ('vegan');


  ### Scaling of arrows to 'fill' a plot with vectors centred at 'at'.
  ### Plot dims from 'par("usr")' and arrow heads are in 'x'.
  $script .= "ordiArrowMul <- function (x, at = c(0,0), fill=0.75) {\n";
  $script .= "  u <- par('usr')\n";
  $script .= "  u <- u - rep(at, each = 2)\n";
  $script .= "  r <- c(range(x[,1], na.rm = TRUE), range(x[,2], na.rm = TRUE))\n";
  ## 'rev' takes care of reversed axes like xlim(1,-1)
  $script .= "  rev <- sign(diff(u))[-2]\n";
  $script .= "  if (rev[1] < 0)\n";
  $script .= "    u[1:2] <- u[2:1]\n";
  $script .= "  if (rev[2] < 0)\n";
  $script .= "    u[3:4] <- u[4:3]\n";
  $script .= "  u <- u/r\n";
  $script .= "  u <- u[is.finite(u) & u > 0]\n";
  $script .= "  fill * min(u)\n";
  $script .= "}\n";

  ### Location of the text at the point of the arrow. 'vect' are the
  ### coordinates of the arrow heads, and 'labels' are the text used to
  ### label these heads, '...' passes arguments (such as 'cex') to
  ### strwidth() and strheight().
  $script .= "ordiArrowTextXY <- function (vect, labels, ...) {\n";
  $script .= "  w <- strwidth(labels, ...)\n";
  $script .= "  h <- strheight(labels, ...)\n";
  ## slope of arrows
  $script .= "  b <- vect[,2]/vect[,1]\n";
  ## offset based on string dimensions
  $script .= "  off <- cbind(sign(vect[,1]) * (w/2 + h/4), 0.75 * h * sign(vect[,2]))\n";
  ## move the centre of the string to the continuation of the arrow
  $script .= "  for(i in 1:nrow(vect)) {\n";
  $script .= "    move <- off[i,2] / b[i]\n";
  ## arrow points to the top/bottom of the text box
  $script .= "    if (is.finite(move) && abs(move) <= abs(off[i, 1]))\n";
  $script .= "      off[i, 1] <- move\n";
  $script .= "    else {\n";
  ## arrow points to a side of the text box
  $script .= "      move <- b[i] * off[i,1]\n";
  $script .= "      off[i, 2] <- move\n";
  $script .= "    }\n";
  $script .= "  }\n";
  $script .= "  off + vect\n";
  $script .= "}\n";

  # Custom version of Dave Robert's ordtest {labdsv} code.
#  $script .= "ordtest <- function (ordpoints,var,dim=c(1:ncol(ordpoints)),index='euclidean',nitr=1000) {\n";
#  $script .= "  tdist <- 0\n";
#  $script .= "  observed <- 0\n";
#  $script .= "  reps <- rep(0,nitr-1)\n";
#  $script .= "  var <- factor(var)\n";
#  $script .= "  for (i in levels(var)) {\n";
#  $script .= "    mask <- var == i\n";
#  $script .= "    tdist <- tdist + sum(dist(ordpoints[mask,dim],index))\n";
#  $script .= "  }\n";
#  $script .= "  observed <- tdist\n";
#  $script .= "  for (i in 1:(nitr-1)) {\n";
#  $script .= "    tdist <- 0\n";
#  $script .= "    var <- sample(var,length(var),replace=FALSE)\n";
#  $script .= "    for (j in levels(var)) {\n";
#  $script .= "      mask <- var == j\n";
#  $script .= "      tdist <- tdist + sum(dist(ordpoints[mask,dim],index))\n";
#  $script .= "    }\n";
#  $script .= "    reps[i] <- tdist\n";
#  $script .= "  }\n";
#  $script .= "  reps\n";
#  $script .= "  out <- list(obs=observed,p=(sum(reps<=observed)+1)/nitr,reps=reps)\n";
#  $script .= "  out\n";
#  $script .= "}\n";


  $script .= $self->$convert2dArray (
    'community_matrix',
    $communityMatrix,
    $sampleNames,
    $communityNames
  );
  if (defined $constrainingMatrix) {
    $script .= $self->$convert2dArray (
      'constraining_matrix',
      $constrainingMatrix,
      $sampleNames,
      $constrainingNames
    );
  }
  if (defined $conditioningMatrix) {
    $script .= $self->$convert2dArray (
      'conditioning_matrix',
      $conditioningMatrix,
      $sampleNames,
      $conditioningNames
    );
#    $script .= "conditioning_matrix[,1] <- factor(conditioning_matrix[,1])\n";
  }
  if (defined $communityCategories) {
    $script .= $self->$convert1dArray (
      'community_categories',
      $communityCategories
    );
  }
  if (defined $sampleCategories) {
    $script .= $self->$convert1dArray (
      'sample_categories',
      $sampleCategories
    );
  }
  if (defined $sampleColors) {
    $script .= $self->$convert1dArray (
      'sample_colors',
      $sampleColors
    );
  }
  if (defined $communityColors) {
    $script .= $self->$convert1dArray (
      'community_colors',
      $communityColors
    );
  }



  # Run the Canonical Correspondence Analysis.
  $script .= "c <- cca(community_matrix";
  $script .= ", constraining_matrix" if (defined $constrainingMatrix);
#  $script .= ", conditioning_matrix" if (defined $conditioningMatrix);
  $script .= ")\n";
#  $script .= "c <- cca(community_matrix";
#  $script .= " ~ constraining_matrix" if (defined $constrainingMatrix);
##  $script .= " + Condition(conditioning_matrix)" if (defined $conditioningMatrix);
#  $script .= ")\n";


  # Save the scores for the species, sites, and biplot.
#  $script .= "g <- scores(c, c(1,2), c('species', 'sites', 'bp'), 2)\n";
  $script .= "g <- scores(c, choices=c(1,2), display=c('species', 'sites', 'bp'))\n";


  # Output the cca text.
  $script .= "print('PIGEON:output')\n";
  $script .= "print(c)\n";



  # Save the sites plot to a file.
  $script .= "png('sites-$file')\n" if ($file =~ /\.png$/i);
  $script .= "pdf('sites-$file')\n" if ($file =~ /\.pdf$/i);
  $script .= "svg('sites-$file')\n" if ($file =~ /\.svg$/i);

  # Draw the plot.
  $script .= "plot(c, type='none')\n";

  # Draw the points for all of the sites.
#  $script .= "points(g\$sites, pch=1, col='black', cex=0.7)\n";
  $script .= "sites <- split(g\$sites, sample_categories)\n";
  my @uniqueSampleCategories = uniq @{$sampleCategories};
  @uniqueSampleCategories = sort @uniqueSampleCategories;
  $script .= $self->$convert1dArray ('unique_sample_categories', \@uniqueSampleCategories);
  for (my $i = 0; $i < @uniqueSampleCategories; $i ++) {
    my $index = $i + 1;
    my $category = $uniqueSampleCategories[$i];
    $script .= "dim(sites\$$category) <- c(length(sites\$$category)/2,2)\n";
    $script .= "points(sites\$$category, pch=19, col=sample_colors[$index], cex=0.7)\n";
#    $script .= "text(sites\$$category, rownames(g\$sites), col=sample_colors[$index], cex=0.7)\n";
    $script .= "ord <- ordiellipse(g\$sites, sample_categories, kind='se', conf=0.9, col=sample_colors[$index], show.groups=$category)\n";

  }
  # Draw the sites legend.
  $script .= "legend('bottomright', legend=unique_sample_categories, pch=19, col=sample_colors, ncol=1, cex=1.0)\n";


  # Draw the axis and arrows for the constraining variables.
  $script .= "mul <- ordiArrowMul(g\$biplot)\n";
  $script .= "attr(g\$biplot, 'arrow.mul') <- mul\n";
  $script .= "arrows(0, 0, mul * g\$biplot[, 1], mul * g\$biplot[, 2], length=0.05, col='blue')\n";
  $script .= "axis(3, at=c(-mul, 0, mul), labels=rep('', 3), col='blue')\n";
  $script .= "axis(4, at=c(-mul, 0, mul), labels=c(-1, 0, 1), col='blue')\n";
  $script .= "biplabs <- ordiArrowTextXY(mul * g\$biplot, rownames(g\$biplot))\n";
  $script .= "text(biplabs, rownames(g\$biplot), col='blue')\n";



  # Save the species plot to a file.
  $script .= "png('species-$file')\n" if ($file =~ /\.png$/i);
  $script .= "pdf('species-$file')\n" if ($file =~ /\.pdf$/i);
  $script .= "svg('species-$file')\n" if ($file =~ /\.svg$/i);

  # Draw the plot.
  $script .= "plot(c, type='none')\n";

  # Draw the points for all of the species.
  $script .= "points(g\$species, pch=15, col='black', cex=0.7)\n";
  $script .= "species <- split(g\$species, community_categories)\n";
  my @uniqueCommunityCategories = uniq @{$communityCategories};
  @uniqueCommunityCategories = sort {
    my ($aletter, $bletter);
    my ($anumber, $bnumber);
    if ($a =~ /([a-zA-Z\']+)(\d+)/) {
      $aletter = $1;
      $anumber = $2;
    }
    if ($b =~ /([a-zA-Z\']+)(\d+)/) {
      $bletter = $1;
      $bnumber = $2;
    }
    if ($aletter eq $bletter) {
      return $anumber <=> $bnumber;
    }
    else {
      return $aletter cmp $bletter;
    }


  } @uniqueCommunityCategories;
  $script .= $self->$convert1dArray ('unique_community_categories', \@uniqueCommunityCategories);
  for (my $i = 0; $i < @uniqueCommunityCategories; $i ++) {
    my $index = $i + 1;
    my $category = $uniqueCommunityCategories[$i];
    $script .= "dim(species\$$category) <- c(length(species\$$category)/2,2)\n";
    $script .= "rownames(species\$$category) <- split(rownames(g\$species), community_categories)\$$category\n";
    $script .= "colnames(species\$$category) <- colnames(g\$species)\n";
    $script .= "points(species\$$category, pch=15, col=community_colors[$index], cex=0.7)\n";
    $script .= "ord <- ordiellipse(g\$species, community_categories, kind='se', conf=0.9, col=community_colors[$index], show.groups=$category)\n";
  }
  # Draw the species legend.
  $script .= "legend('bottomright', legend=unique_community_categories, pch=15, col=community_colors, ncol=1, cex=1.0)\n";



  # Draw the axis and arrows for the constraining variables.
  $script .= "mul <- ordiArrowMul(g\$biplot)\n";
  $script .= "attr(g\$biplot, 'arrow.mul') <- mul\n";
  $script .= "arrows(0, 0, mul * g\$biplot[, 1], mul * g\$biplot[, 2], length=0.05, col='blue')\n";
  $script .= "axis(3, at=c(-mul, 0, mul), labels=rep('', 3), col='blue')\n";
  $script .= "axis(4, at=c(-mul, 0, mul), labels=c(-1, 0, 1), col='blue')\n";
  $script .= "biplabs <- ordiArrowTextXY(mul * g\$biplot, rownames(g\$biplot))\n";
  $script .= "text(biplabs, rownames(g\$biplot), col='blue')\n";
  # Finish the script.
  $script .= "q()\n";

print $script;

  # Run the script.
  my %vars = $self->$R ($script);

  return $vars{output};
}

1;

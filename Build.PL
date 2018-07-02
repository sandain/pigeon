#! /usr/bin/perl

use Module::Build;

my $build = Module::Build->new (
  module_name   => 'Pigeon',
  license       => 'gpl',
  dist_abstract => 'Pigeon - A tool for metagenome analysis.',
  requires      => {
    'perl'                          => '5.6.1',
    'Bio::Root::Version'            => '1.006',
    'File::Temp'                    => '0.22',
    'GD'                            => '2.39',
    'GD::Graph'                     => '1.44',
    'Image::Magick'                 => '',
    'IO::Uncompress::AnyUncompress' => '2.00',
    'List::Util'                    => '1.21',
    'POSIX'                         => '1.13'
  },
);
$build->create_build_script;

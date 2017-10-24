requires 'perl', 'v5.14';

on 'test', sub {
  requires 'Test::Simple', '1.001003';
  requires 'Test::More', '1.001003';
  requires 'Test::Exception','0.32';
  requires 'Test::Pod','1.49';
};

requires 'Catmandu', '1.06';
requires 'Furl', '3.13';
requires 'GitLab::API::v3', '1.00';
requires 'Test::JSON', '0.11';
requires 'URL::Encode', '0.03';
requires 'IO::File';
requires 'IO::File::WithFilename';

# Need recent SSL to talk to https endpoint correctly
requires 'IO::Socket::SSL', '2.015';

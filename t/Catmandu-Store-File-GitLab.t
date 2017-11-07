use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;
use Data::Dumper;

my $baseurl = $ENV{GITLAB_URL}     || "";
my $token   = $ENV{GITLAB_TOKEN}   || "";
my $username = $ENV{GITLAB_USER} || "";

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Store::File::GitLab';
    use_ok $pkg;
}
require_ok $pkg;

SKIP: {
    skip
        "No GitLab server environment settings found (GITLAB_URL, GITLAB_TOKEN, GITLAB_USER).",
        5
        if (!$baseurl || !$token || !$username);

    dies_ok { $pkg->new() } "missing arguments";
    lives_ok { $pkg->new(baseurl => $baseurl, token =>$token, user => $username) } "missing arguments";

    my $store = $pkg->new(baseurl => $baseurl, token =>$token, user => $username);

    ok $store , 'got a store';

    my $bags = $store->bag();

    ok $bags , 'store->bag()';

    isa_ok $bags , 'Catmandu::Store::File::GitLab::Index';

    throws_ok { $store->bag('1235') } 'Catmandu::Error',
        'bag(1235) doesnt exist';

    my $index = $store->index;

    ok $index , 'got an index';

    is_deeply $index->to_array, [], "now repos there";
}

done_testing;

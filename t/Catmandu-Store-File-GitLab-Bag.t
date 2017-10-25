use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;
use IO::File;
use IO::File::WithFilename;
use Catmandu::Store::File::GitLab;

my $baseurl = $ENV{GITLAB_URL}     || "";
my $token   = $ENV{GITLAB_TOKEN}   || "";
my $username = $ENV{GITLAB_USER} || "";

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Store::File::GitLab::Bag';
    use_ok $pkg;
}
require_ok $pkg;

SKIP: {
    skip
        "No GitLab server environment settings found (GITLAB_URL, GITLAB_TOKEN, GITLAB_USER).",
        5
        if (!$baseurl || !$token || !$username);

    my $store = Catmandu::Store::File::GitLab->new(
        baseurl => $baseurl,
        token   => $token,
        user    => $username,
    );

    ok $store , 'got a store';

    my $index = $store->bag;

    ok $index , 'got an index';

    ok $index->add({_id => 1234}), 'adding bag `1234`';

    my $bag = $store->bag('1234');

    ok $bag , 'got bag(1234)';

    note("add");
    {
        ok $bag->upload(IO::File->new('t/marc.xml'),
            'marc.xml');
    }
    note("list");
    {
        my $array = [sort @{$bag->map(sub {shift->{_id}})->to_array}];

        ok $array , 'list got a response';

        is_deeply $array , [qw(marc.xml)],
            'got correct response';
    }

    note("exists");
    {
        is $bag->exists("marc.xml"), 1, "file exists";

        is $bag->exists->("Idonotexist.txt"), 0, "file does not exist";
    }

    note("get");
    {
        my $file = $bag->get("marc.xml");
        ok $file;

        my $str = $bag->as_string_utf8($file);

        ok $str , 'can stream the data';

        like $str , qr/<\?xml version="1.0"/,
            'got the correct data';
    }

    note("delete");
    {
        ok $bag->delete('marc.xml'), 'marc.xml)';

        my $array = [sort @{$bag->map(sub {shift->{_id}})->to_array}];

        ok $array , 'list got a response';

        is_deeply $array , [qw(obj_demo_40.zip)], 'got correct response';
    }

    # note("delete_all");
    # {
    #     lives_ok {$bag->delete_all()} 'delete_all';
    #
    #     my $array = $bag->to_array;
    #
    #     is_deeply $array , [], 'got correct response';
    # }
    #
    # ok $index->delete('1234'), 'delete(1234)';
}

done_testing;

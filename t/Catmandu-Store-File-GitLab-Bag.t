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

my $repo_name = "testing";

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

    ok $index->add({_id => $repo_name}), "adding bag $repo_name";

    my $bag = $store->bag($repo_name);

    ok $bag , "got bag $repo_name";

    note("add");
    {
        is_deeply $bag->to_array(), [], "empty array before add";

        ok $bag->upload(IO::File->new('t/marc.xml'),
            'marc.xml');
        ok $bag->upload(IO::File->new('t/test.json'),
            'data/test.json');
    }

    note("list");
    {
        my $array = [sort @{$bag->map(sub {shift->{_id}})->to_array}];

        ok $array , 'list got a response';

        is_deeply $array , [qw(data/test.json marc.xml)],
            'got correct response';
    }

    note("exists");
    {
        is $bag->exists("marc.xml"), 1, "file exists";

        ok ! $bag->exists("Idonotexist.txt"), "file does not exist";
    }

    note("get");
    {
        my $file = $bag->get("marc.xml");
        ok $file;
        is $file->{_id}, "marc.xml", "got correct file";

        my $str = $bag->as_string_utf8($file);

        ok $str , 'can stream the data';

        like $str , qr/<\?xml version="1.0"/,
            'got the correct data';

        $file = $bag->get("data/test.json");
        ok $file;
        is $file->{_id}, "data/test.json", "got correct file";
    }

    note("delete");
    {
        ok $bag->delete('marc.xml'), 'can delete file';

        my $array = [sort @{$bag->map(sub {shift->{_id}})->to_array}];

        ok $array , 'list got a response after delete';
        is_deeply $array , ["data/test.json"],
            'got one item after delete';

    }

    note("delete_all");
    {
        lives_ok {$bag->delete_all()} 'can delete_all';

        my $array = $bag->to_array;

        is_deeply $array , [], 'list gives correct response: empty after delete_all';
    }

    ok $index->delete($repo_name), "delete repo $repo_name";
}

done_testing;

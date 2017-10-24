use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;
use Catmandu::Store::File::GitLab;
use Data::Dumper;

my $baseurl = $ENV{GITLAB_URL}     || "";
my $token   = $ENV{GITLAB_TOKEN}   || "";
my $username = $ENV{GITLAB_USER} || "";

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Store::File::GitLab::Index';
    use_ok $pkg;
}
require_ok $pkg;

SKIP: {
    skip
        "No GitLab server environment settings found (GITLAB_URL, GITLAB_TOKEN, GITLAB_USER).",
        5
        if (!$baseurl || !$token || !$username);

    my $testrepo = "testproject2";

    my $store = Catmandu::Store::File::GitLab->new(
        baseurl => $baseurl,
        token   => $token,
        user    => $username,
    );

    ok $store , 'got a store';

    my $index;

    note("index");
    {
        $index = $store->bag();

        ok $index , 'got the index bag';
    }

    note("list");
    {
        my $array = $index->to_array;

        ok $array , 'list got a response';
        is @$array, 0, "list gives empty array"
    }

    note("exists");
    {
        my $exists = $index->exists($testrepo);
        is $exists, 0, "check repo does not exist";
    }

    note("add");
    {
        ok my $new = $index->add({_id => $testrepo}), "create repo";
        is $new->{_id}, $testrepo, "correct repo created";

        my $exists = $index->exists($testrepo);
        is $exists, 1, "check if repo exists";

        my $array = $index->to_array;
        ok $array , 'list got a response';
        is @$array, 1, "list gives one record"
    }

    note("get");
    {
        ok my $repo = $index->get($testrepo), "get added repo";
        is $repo->{_id}, $testrepo, "get correct repo after add";
    }

    note("delete");
    {
        ok my $res = $index->delete($testrepo), 'delete our test repo';

        sleep 2;
        ok my $repo = $index->get($testrepo), "get added repo";
        ok ! $repo->{_id}, "nothing to get";

        my $array = $index->to_array;
        ok $array , 'list got a response after delete';
        is @$array, 0, "list gives empty array after delete"
    }
}

done_testing;

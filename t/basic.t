use strict;
use warnings FATAL => 'all';
use Test::More;

BEGIN { use_ok( 'Catmandu::Store::GitLab' ); }
require_ok('Catmandu::Store::GitLab');

my $baseurl = $ENV{GITLAB_URL} || "";
my $token = $ENV{GITLAB_TOKEN} || "";

SKIP: {
    skip "No GitLab server environment settings found (GITLAB_URL, GITLAB_TOKEN).", 5 if (! $host || ! $token);

    ok($x = Catmandu::Store::GitLab->new(baseurl => $baseurl, token => $token), "new store");

    ok($x->gitlab, 'gitlab');

    my $count = 0;
    $x->bag('demo')->take(10)->each(sub {
        my $obj = $_[0];
        $count++;
        ok($obj,"take(10) - $count");
    });

    ok($obj = $x->bag('demo')->add({ title => ['test']}), 'add');

    my $pid = $obj->{_id};

    ok($pid,"pid = $pid");

    is($obj->{title}->[0] , 'test' , 'obj content ok');

    $obj->{creator}->[0] = 'Patrick';

    ok($x->bag('demo')->add($obj),'update using add');

    ok($x->bag('demo')->get($pid), 'get');

    is($obj->{creator}->[0] , 'Patrick' , 'obj content ok');

    # ok($x->bag('demo')->delete($pid), "delete $pid");
    # print Dumper($x->bag->delete_all());

}
done_testing;

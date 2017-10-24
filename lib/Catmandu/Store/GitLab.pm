package Catmandu::Store::GitLab;

# DO I NEED THIS??

use Catmandu::Sane;
use GitLab::API::v3;
use Moo;

with 'Catmandu::Store';

has baseurl => (is => 'ro', required => 1);
has token   => (is => 'ro', required => 1);

has gitlab =>
    (is => 'ro', init_arg => undef, lazy => 1, builder => '_build_gitlab',);

sub _build_gitlab {
    my ($self) = @_;

    GitLab::API::v3->new(url => $self->baseurl, token => $self->token,);
}

package Catmandu::Store::GitLab::Bag;

use Catmandu::Sane;
use Moo;
use Catmandu::Util qw(:is);

with 'Catmandu::Bag';

sub generator {

}

1;

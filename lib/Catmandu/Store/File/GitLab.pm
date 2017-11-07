package Catmandu::Store::File::GitLab;

use Catmandu::Sane;
use Catmandu;
use Catmandu::Store::File::GitLab::Bag;
use Catmandu::Store::File::GitLab::Index;
use GitLab::API::v3;
use Moo;
use namespace::clean;

with 'Catmandu::FileStore', 'Catmandu::Droppable';

has baseurl => (is  => 'ro', required => 1);
has token     => (is => 'ro', required => 1);
has user => (is => 'ro', required => 1);
has gitlab    => (is => 'lazy');

sub _build_gitlab {
    my ($self) = @_;

    GitLab::API::v3->new(
        url => $self->baseurl,
        token => $self->token
    );
}

sub drop {
    my ($self) = @_;

    $self->index->delete_all;
}

1;

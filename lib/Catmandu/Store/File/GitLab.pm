package Catmandu::Store::File::GitLab;

use Catmandu::Sane;
use Moo;
use Carp;
use Catmandu;
use GitLab::API::v3;
use Catmandu::Store::File::GitLab::Index;
use Catmandu::Store::File::GitLab::Bag;
use namespace::clean;

with 'Catmandu::FileStore', 'Catmandu::Droppable';

has baseurl     => (is => 'ro', default => sub {'http://localhost:8080/fedora'});
has token => (is => 'ro', default => sub {'s3cret'});
has gitlab => (is => 'lazy');

sub _build_gitlab {
    my ($self) = @_;

    GitLab::API::v3->new(
        url   => $self->baseurl,
        token => $self->token,
    );
}


sub drop {
    my ($self) = @_;

    $self->index->delete_all;
}

1;

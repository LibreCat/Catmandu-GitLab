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

=pod

=head1 NAME

Catmandu::Store::File::GitLab - a file store on gilab

=head1 SYNOPSIS

    # From the command line

    # Export a list of all file containers
    $ catmandu export File::GitLab --baseurl https://my.gitlab_host.org --token 1234ABC --user gitty to YAML

    # Export a list of all files in repository 'my_project' # TODO
    $ catmandu export gitlab --bag my_project to YAML

    # Add a file to the repository 'my_project'
    $ catmandu stream /tmp/myfile.txt to gitlab --bag my_project --id myfile.txt

    # Download the file 'myfile.txt' from the repository 'my_project'
    $ catmandu stream gitlab --bag 1234 --id myfile.txt to /tmp/output.txt

    # Delete the file 'myfile.txt' from the repository 'my_project'
    $ catmandu delete gitlab --bag 1234 --id myfile.txt

    # From Perl

=head1 CONFIGURATION



=cut

package Catmandu::Store::File::GitLab::Index;

use Catmandu::Sane;
use Carp;
use Furl;
use Moo;
use URL::Encode qw(url_encode);
use namespace::clean;

with 'Catmandu::Bag';
with 'Catmandu::FileBag::Index';
with 'Catmandu::Droppable';

sub generator {
    my ($self) = @_;

    my $gitlab = $self->store->gitlab;

    $self->log->debug(
        "Creating generator for GitLab @ " . $self->store->baseurl);

    return sub {
        state $projects = $gitlab->paginator('owned_projects');

        while (my $project = $projects->next()) {

            return {_id => $project->{path_with_namespace},};
        }

        return undef;

    };
}

sub exists {
    my ($self, $key) = @_;

    croak "Need a key" unless defined $key;

    $self->log->debug("Checking if repo exists with name $key");

    my $repo = $self->get($key);

    $repo->{name} ? 1 : 0;
}

sub add {
    my ($self, $data) = @_;

    croak "Need a '_id' field" unless defined $data->{_id};

    my $gitlab = $self->store->gitlab;

    $self->log->debug("Creating repo with name $data->{_id}");

    if (!$self->exists($data->{_id})) {
        my $data = $gitlab->create_project({name => $data->{_id}});
        $data->{_id} = $data->{name};
        $data;
    }
    else {
        $self->get($data->{_id});
    }
}

sub get {
    my ($self, $key) = @_;

    croak "Need a key" unless defined $key;

    my $gitlab = $self->store->gitlab;

    $self->log->debug("Loading repo with name $key");

    my $repo_id = $self->store->user . "/" . $key;
    url_encode($repo_id);
    my $project = $gitlab->project($repo_id);

    $project->{_id} = $project->{name};

    return $project;
}

sub delete {
    my ($self, $key) = @_;

    croak "Need a key" unless defined $key;

    my $gitlab = $self->store->gitlab;

    $self->log->debug("Deleting repo with name $key");

    my $repo_id = $self->store->user . "/" . $key;
    url_encode($repo_id);
    my $res = $gitlab->delete_project($repo_id);

    1;
}

sub delete_all {
    my ($self) = @_;

    $self->log->debug("Start delete_all for for store gitlab");

    $self->each(
        sub {
            my $key = shift->{_id};
            $self->delete($key);
        }
    );

    1;
}

sub drop {
    my ($self) = @_;

    $self->log->debug("Dropping store gitlab");

    $self->delete_all;
}

sub commit {
    return 1;
}

1;

__END__

=pod

=head1 NAME

Catmandu::Store::File::GitLab::Index - Index of all repostories in a Catmandu::Store::File::GitLab

=head1 SYNOPSIS

    use Catmandu;

    my $store = Catmandu->store('File::GitLab'
                        , baseurl   => 'http://localhost:8080/gitlab'
                        , username  => 'userX'
                        , token  => '12345'
                        );

    my $index = $store->index;

    # List all repositories
    $index->each(sub {
        my $repo = shift;

        print "%s\n" , $repo->{_id};
    });

    # Create a new repository
    $index->add({_id => '1234'});

    # Delete a repository
    $index->delete(1234);

    # Get a repository
    my $repo = $index->get(1234);

    # Get the files in a repository
    my $files = $index->files(1234);

    $files->each(sub {
        my $file = shift;

        my $name         = $file->_id;
        my $size         = $file->size;
        my $content_type = $file->content_type;
        my $created      = $file->created;
        my $modified     = $file->modified;

        $file->stream(IO::File->new(">/tmp/$name"), file);
    });

    # Add a file
    $files->upload(IO::File->new("<data.dat"),"data.dat");

    # Retrieve a file
    my $file = $files->get("data.dat");

    # Stream a file to an IO::Handle
    $files->stream(IO::File->new(">data.dat"),$file);

    # Delete a file
    $files->delete("data.dat");

    # Delete a repository
    $index->delete("1234");

=head1 DESCRIPTION

A L<Catmandu::Store::File::GitLab::Index> contains all repositories available in a
L<Catmandu::Store::File::GitLab> FileStore. All methods of L<Catmandu::Bag>,
L<Catmandu::FileBag::Index> and L<Catmandu::Droppable> are
implemented.

Every L<Catmandu::Bag> is also an L<Catmandu::Iterable>.

=head1 Repositories

All files in a L<Catmandu::Store::File::GitLab> are organized in repositories. To add
a repository a new record needs to be added to the L<Catmandu::Store::File::GitLab::Index> :

    $index->add({_id => '1234'});

The C<_id> field is the only metadata available in GitLab stores. To add more
metadata fields to a GitLab store a L<Catmandu::Plugin::SideCar> is required.

=head1 FILES

Files can be accessed via the repository identifier:

    my $files = $index->files('1234');

Use the C<upload> method to add new files to a "folder". Use the C<download> method
to retrieve files from a "folder".

    $files->upload(IO::File->new("</tmp/data.txt"),'data.txt');

    my $file = $files->get('data.txt');

    $files->download(IO::File->new(">/tmp/data.txt"),$file);

=head1 METHODS

=head2 each(\&callback)

Execute C<callback> on every repository in the GitLab store. See L<Catmandu::Iterable> for more
iterator functions

=head2 exists($id)

Returns true when a repository with identifier $id exists.

=head2 add($hash)

Adds a new repository to the GitLab store. The $hash must contain an C<_id> field.

=head2 get($id)

Returns a hash containing the metadata of the repository. In the GitLab store this hash
will contain only the repository idenitifier.

=head2 files($id)

Return the L<Catmandu::Store::File::GitLab::Bag> that contains all "files" in the repository
with identifier $id.

=head2 delete($id)

Delete the repository with identifier $id, if exists.

=head2 delete_all()

Delete all folders in this store.

=head2 drop()

Delete the store.

=head1 SEE ALSO

L<Catmandu::Store::File::GitLab::Bag> ,
L<Catmandu::Store::File::GitLab> ,
L<Catmandu::FileBag::Index> ,
L<Catmandu::Plugin::SideCar> ,
L<Catmandu::Bag> ,
L<Catmandu::Droppable> ,
L<Catmandu::Iterable>

=cut

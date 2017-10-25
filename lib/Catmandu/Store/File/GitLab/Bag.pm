package Catmandu::Store::File::GitLab::Bag;

use Catmandu::Sane;
use Carp;
use JSON;
use Moo;
# use Catmandu::Util qw(content_type);
use URL::Encode qw(url_encode);
use namespace::clean;

with 'Catmandu::Bag';
with 'Catmandu::FileBag';
with 'Catmandu::Droppable';

sub generator {
    my ($self) = @_;

    my $gitlab = $self->store->gitlab;

    my $repo_id = $self->store->user . "/" . $self->name;
    url_encode($repo_id);

    my $tree = $gitlab->tree($repo_id);

    return sub {
        while (my $obj = pop @$tree) {
            if ($obj->{id} && $obj->{type} eq "blob") {
                $obj->{_id} = delete $obj->{name};
                return $obj;
            }
        }

        return undef;
    };

}

sub exists {
    my ($self, $key) = @_;

    defined ($self->_get($key)->{file_name}) ? 1 : undef;
}

sub get {
    my ($self, $key) = @_;

    $self->_get($key);
}

sub add {
    my ($self, $data) = @_;

    my $key = $data->{_id};
    my $io  = $data->{_stream};
# die <$io>
    # if ($io->can('filename')) {
        # my $filename = $io->filename;
    $self->log->debug("adding a stream from the filename");
    return $self->_add_filename($key, $io);
    # }
    # else ...
}

sub delete {
    my ($self, $key) = @_;

    return undef unless $key;

    my $gitlab = $self->store->gitlab;

    my $repo_id = $self->store->user . "/" . $self->name;
    url_encode($repo_id);

    $gitlab->delete_file(
        $repo_id,
        {file_path => $key},
    );

    1;
}

sub delete_all {
    my ($self) = @_;

    $self->each(
        sub {
            my $key = shift->{_id};
            $self->delete($key);
        }
    );

    1;
}

sub drop {
    $_[0]->delete_all;
}

sub commit {
    return 1;
}

sub _get {
    my ($self, $key) = @_;

    my $gitlab = $self->store->gitlab;

    my $repo_id = $self->store->user . "/" . $self->name;
    url_encode($repo_id);

    $gitlab->file(
        $repo_id,
        {
            file_path => $key,
            ref => "master",
        }
    );
}

sub _add_filename {
    my ($self, $key, $io) = @_;

    my $gitlab = $self->store->gitlab;

    my $repo_id = $self->store->user . "/" . $self->name;
    url_encode($repo_id);

    # hack
    my $content;
    while(<$io>) {
        $content .= $_;
    };

    $gitlab->create_file(
        $repo_id,
        {
            file_path => $key,
            branch_name => "master",
            content => $content,
            commit_message => "Mega Commit by Catmandu-GitLab",
        }
    );
}

1;

=pod

=head1 NAME

Catmandu::Store::File::GitLab::Bag - Index of all "files" in a Catmandu::Store::File::GitLab repository

=head1 SYNOPSIS

    use Catmandu;

    my $store = Catmandu->store('File::GitLab'
                        , baseurl   => 'http://localhost:8080/gitlab'
                        , username  => 'gitlabAdmin'
                        , password  => 'gitlabAdmin'
                        , namespace => 'demo'
                        , purge     => 1);

    my $index = $store->index;

    # List all repository
    $index->each(sub {
        my $container = shift;

        print "%s\n" , $container->{_id};
    });

    # Add a new repository
    $index->add({_id => 'my_project'});

    # Delete a repository
    $index->delete('my_project');

    # Get a repository
    my $folder = $index->get('my_project');

    # Get the files in a repository
    my $files = $index->files('my_project');

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

    # or (faster)
    $files->upload(IO::File::WithFilename->new("<data.dat"),"data.dat");

    # Retrieve a file
    my $file = $files->get("data.dat");

    # Stream a file to an IO::Handle
    $files->stream(IO::File->new(">data.dat"),$file);

    # Delete a file
    $files->delete("data.dat");

    # Delete a repository
    $index->delete('my_project');

=head1 DESCRIPTION

A L<Catmandu::Store::File::GitLab::Bag> contains all "files" available in a
L<Catmandu::Store::File::GitLab> FileStore repository. All methods of L<Catmandu::Bag>,
L<Catmandu::FileBag::Index> and L<Catmandu::Droppable> are
implemented.

Every L<Catmandu::Bag> is also an L<Catmandu::Iterable>.

=head1 FOLDERS

All files in a L<Catmandu::Store::File::GitLab> are organized in "folders". To add
a "folder" a new record needs to be added to the L<Catmandu::Store::File::GitLab::Index> :

    $index->add({_id => '1234'});

The C<_id> field is the only metadata available in GitLab stores. To add more
metadata fields to a GitLab store a L<Catmandu::Plugin::SideCar> is required.

=head1 FILES

Files can be accessed via the "folder" identifier:

    my $files = $index->files('1234');

Use the C<upload> method to add new files to a "folder". Use the C<download> method
to retrieve files from a "folder".

    $files->upload(IO::File->new("</tmp/data.txt"),'data.txt');

    my $file = $files->get('data.txt');

    $files->download(IO::File->new(">/tmp/data.txt"),$file);

=head1 METHODS

=head2 each(\&callback)

Execute C<callback> on every "file" in the GitLab store "folder". See L<Catmandu::Iterable> for more
iterator functions

=head2 exists($name)

Returns true when a "file" with identifier $name exists.

=head2 add($hash)

Adds a new "file" to the GitLab store "folder". It is very much advised to use the
C<upload> method below to add new files

=head2 get($id)

Returns a hash containing the metadata of the file. The hash contains:

    * _id : the file name
    * size : file file size
    * content_type : the content_type
    * created : the creation date of the file
    * modified : the modification date of the file
    * _stream: a callback function to write the contents of a file to an L<IO::Handle>

If is very much advised to use the C<stream> method below to retrieve files from
the store.

=head2 delete($name)

Delete the "file" with name $name, if exists.

=head2 delete_all()

Delete all files in this folder.

=head2 upload(IO::Handle,$name)

Upload the IO::Handle reference to the GitLab store "folder" and use $name as identifier.

GitLab bags will have a faster upload using L<IO::File::WithFilename> as
IO::Handles

=head2 stream(IO::Handle,$file)

Write the contents of the $file returned by C<get> to the IO::Handle.

=head1 SEE ALSO

L<Catmandu::Store::File::GitLab::Bag> ,
L<Catmandu::Store::File::GitLab> ,
L<Catmandu::FileBag::Index> ,
L<Catmandu::Plugin::SideCar> ,
L<Catmandu::Bag> ,
L<Catmandu::Droppable> ,
L<Catmandu::Iterable>

=cut

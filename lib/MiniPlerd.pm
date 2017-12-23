package MiniPlerd;
our $VERSION = '1.53';

use URI;
use Moose;
use Template;
use DateTime;
use DateTime::Format::W3CDTF;
use Path::Class::Dir;
use File::Copy::Recursive qw/dircopy/;

use MiniPlerd::Post;

has 'base_uri_path'  => (is => 'ro', isa => 'Str', default => 'https://kyzn.org/');
has 'base_uri'       => (is => 'ro', isa => 'URI', lazy_build => 1);

has 'title'          => (is => 'ro', isa => 'Str', default => 'kivanc\'s blog');
has 'author_name'    => (is => 'ro', isa => 'Str', default => 'Kivanc Yazan');
has 'author_email'   => (is => 'ro', isa => 'Str', default => 'kyzn@cpan.org');

has 'blogs_path'     => (is => 'ro', isa => 'Str', default => '/home/kivanc/kyzn.org/blogs');
has 'templates_path' => (is => 'ro', isa => 'Str', default => '/home/kivanc/kyzn.org/templates');
has 'extras_path'    => (is => 'ro', isa => 'Str', default => '/home/kivanc/kyzn.org/extras');
has 'output_path'    => (is => 'ro', isa => 'Str', default => '/var/www/html');

has 'blogs_dir'      => (is => 'ro', isa => 'Path::Class::Dir',  lazy_build => 1);
has 'templates_dir'  => (is => 'ro', isa => 'Path::Class::Dir',  lazy_build => 1);
has 'extras_dir'     => (is => 'ro', isa => 'Path::Class::Dir',  lazy_build => 1);
has 'output_dir'     => (is => 'ro', isa => 'Path::Class::Dir',  lazy_build => 1);

has 'post_tt_file'   => (is => 'ro', isa => 'Path::Class::File', lazy_build => 1);
has 'rss_tt_file'    => (is => 'ro', isa => 'Path::Class::File', lazy_build => 1);
has 'jf_tt_file'     => (is => 'ro', isa => 'Path::Class::File', lazy_build => 1);
has 'index_file'     => (is => 'ro', isa => 'Path::Class::File', lazy_build => 1);
has 'rss_file'       => (is => 'ro', isa => 'Path::Class::File', lazy_build => 1);
has 'jf_file'        => (is => 'ro', isa => 'Path::Class::File', lazy_build => 1);

has 'template'       => (is => 'ro', isa => 'Template',                  lazy_build => 1);
has 'posts'          => (is => 'ro', isa => 'ArrayRef[MiniPlerd::Post]', lazy_build => 1);
has 'recent_posts'   => (is => 'ro', isa => 'ArrayRef[MiniPlerd::Post]', lazy_build => 1);

has 'datetime_formatter' => (is => 'ro', isa => 'DateTime::Format::W3CDTF',
                             default => sub { DateTime::Format::W3CDTF->new });

sub _build_base_uri {
  return URI->new(shift->base_uri_path);
}

sub _build_blogs_dir {
  return Path::Class::Dir->new(shift->blogs_path);
}

sub _build_templates_dir {
  return Path::Class::Dir->new(shift->templates_path);
}

sub _build_extras_dir {
  return Path::Class::Dir->new(shift->extras_path);
}

sub _build_output_dir {
  return Path::Class::Dir->new(shift->output_path);
}

sub _build_post_tt_file {
  return Path::Class::File->new(shift->templates_dir,'post.tt');
}

sub _build_rss_tt_file {
  return Path::Class::File->new(shift->templates_dir,'atom.tt');
}

sub _build_jf_tt_file {
  return Path::Class::File->new(shift->templates_dir,'jf.tt');
}

sub _build_index_file {
  return Path::Class::File->new(shift->output_dir,'index.html');
}

sub _build_rss_file {
  return Path::Class::File->new(shift->output_dir,'atom.xml');
}

sub _build_jf_file {
  return Path::Class::File->new(shift->output_dir,'feed.json');
}

sub _build_template {
  my $self = shift;
  return Template->new( {
    INCLUDE_PATH => $self->templates_dir,
    FILTERS => {
      json => sub {
        my $text = shift;
        $text =~ s/"/\\"/g;
        $text =~ s/\n/\\n/g;
        return $text;
      }
    },
  } );
}

sub _build_posts {
  my $self = shift;
  my @posts = sort { $b->date <=> $a->date }
              map  { MiniPlerd::Post->new( plerd => $self, blog_file => $_ ) }
              grep { /\.markdown$|\.md$/ }
              $self->blogs_dir->children;
  return \@posts;
}

sub _build_recent_posts {
  return [shift->posts->[0]];
}

sub publish_index_page {
  my $self = shift;

  $self->template->process(
    $self->post_tt_file->openr,
    {
      plerd => $self,
      posts => $self->recent_posts,
      title => $self->title,
    },
    $self->index_file->openw,
  );
}

sub publish_feed {
  my ($self, $feed_type) = @_;
  my $tt_file = $feed_type eq 'rss' ? 'rss_tt_file' : 'jf_tt_file';
  my $file    = $feed_type eq 'rss' ? 'rss_file'    : 'jf_file';

  my $timestamp = $self->datetime_formatter
                  ->format_datetime(DateTime->now(time_zone => 'local'));

  $self->template->process(
    $self->$tt_file->openr,
    {
      plerd => $self,
      posts => $self->recent_posts,
      timestamp => $timestamp,
    },
    $self->$file->openw,
  );
}

sub publish_extras {
  my $self = shift;
  dircopy($self->extras_path,$self->output_path);
}

sub publish_all {
  my $self = shift;

  $_->publish foreach $self->posts->@*;
  $self->publish_index_page;
  $self->publish_feed($_) foreach [qw/rss jf/];
  $self->publish_extras;
}

1;

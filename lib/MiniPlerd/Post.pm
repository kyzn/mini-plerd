package MiniPlerd::Post;

use Moose;
use DateTime;
use DateTime::Format::W3CDTF;
use Text::MultiMarkdown qw( markdown );
use Text::SmartyPants;
use URI;
use HTML::Strip;

use Readonly;


has 'uri'   => (is => 'ro', isa => 'URI', lazy_build => 1);
has 'title' => (is => 'rw', isa => 'Str');
has 'body'  => (is => 'rw', isa => 'Str');
has 'date'  => (is => 'rw', isa => 'DateTime', handles => [qw/month_name day year/]);
has 'plerd' => (is => 'ro', isa => 'MiniPlerd', required => 1, weak_ref => 1);


has 'blog_file'           => (is => 'ro', isa => 'Path::Class::File', required => 1,
                              trigger => \&_process_blog_file);
has 'output_file'         => (is => 'ro', isa => 'Path::Class::File', lazy_build => 1);
has 'output_filename'     => (is => 'rw', isa => 'Str', lazy_build => 1);
has 'published_timestamp' => (is => 'ro', isa => 'Str', lazy_build => 1);

sub _build_uri {
  my $self = shift;
  return URI->new_abs($self->output_filename, $self->plerd->base_uri);
}

sub _build_output_file {
  my $self = shift;
  return Path::Class::File->new(
    $self->plerd->output_dir, $self->output_filename);
}

sub _build_output_filename {
  return shift->blog_file->basename =~ s/\..*$/.html/r;
}

sub _build_published_timestamp {
  my $self = shift;
  return $self->plerd->datetime_formatter->format_datetime($self->date);
}

sub _process_blog_file {
  my $self = shift;
  my $fh   = $self->blog_file->openr;
  my $title_line = <$fh>; chomp $title_line;
  my $time_line  = <$fh>; chomp $time_line;
  $self->title($title_line);
  $self->date($self->plerd->datetime_formatter->parse_datetime($time_line));
  $self->date->set_time_zone('local');

  $self->body(join '', <$fh>);
  $self->$_(Text::SmartyPants::process(markdown($self->$_)))
    foreach qw/title body/;
  $self->title($self->title =~ s/<\/?p>\s*//gr);
}

sub publish {
  my $self = shift;

  $self->plerd->template->process(
    $self->plerd->post_tt_file->openr,
    {
      plerd => $self->plerd,
      posts => [ $self ],
      title => $self->title =~ s/<\/?(em|strong)>//gr,
      context_post => $self,
    },
    $self->output_file->openw,
  );
}

1;

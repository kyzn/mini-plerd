## mini-plerd

This is a clone of Jason McIntosh's [plerd](https://github.com/jmacdotorg/plerd) that I modified to have just what I needed for [kivanc's blog](https://kyzn.org). For actual blog content that is processed by this script, see [kyzn.org](https://github.com/kyzn/kyzn.org).

## depends on

```cpanm DateTime DateTime::Format::W3CDTF File::Copy::Recursive FindBin Moose Path::Class Readonly Template Text::MultiMarkdown URI HTML::Strip```

## provides

- MiniPlerd
- MiniPlerd::Post
- and Text::SmartyPants, because when you do `cpanm Text::SmartyPants`, it tries to bring in half of CPAN, and often some modules won't be installed successfully. Also see [jmacdotorg/plerd/f91c6c9e](https://github.com/jmacdotorg/plerd/commit/f91c6c9ee9e8ebe9864ecceef98e830353e130c2).

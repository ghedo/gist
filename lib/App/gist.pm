package App::gist;

use File::Basename;
use WWW::GitHub::Gist;

use warnings;
use strict;

=head1 NAME

App::gist - GitHub Gist creator

=head1 SYNOPSIS

Synopsis section

    use feature 'say';
    use App::gist;

    use warnings;
    use strict;

    say 'Created gist: '.App::gist -> new($file, $extension) -> run;

=head1 METHODS

=head2 new( $file, $extension )

Create a App::gist object using the given file and its extension.

=cut

sub new {
	my ($class, $file, $ext) = @_;

	my $login	= $ENV{GITHUB_USER} || `git config github.user`;
	my $token	= $ENV{GITHUB_TOKEN} || `git config github.token`;

	chomp $login; chomp $token;

	my $opts = {
		'file'  => $file,
		'ext'   => $ext,
		'login' => $login,
		'token' => $token
	};

	return bless $opts, $class;
}

=head2 run( )

Just run the app.

=cut

sub run {
	my $self = shift;

	my ($login, $token, $ext);

	if (!$self -> {'login'}) {
		print STDERR "Enter username: ";
		chop($login = <STDIN>);
	} else {
		$login = $self -> {'login'};
	}

	if (!$self -> {'token'}) {
		print STDERR "Enter token for '$login': ";
		system('stty','-echo') if $^O eq 'linux';
		chop($login = <STDIN>);
		system('stty','echo') if $^O eq 'linux';
		print "\n";
	} else {
		$token = $self -> {'token'};
	}

	open(FILE, $self -> {'file'}) or die "Err: Enter a valid file name.\n";
	my $data = join('', <FILE>);
	close FILE;

	my $basename	= basename($self -> {'file'});

	if (!$self -> {'ext'}) {
		$ext	= ".".($basename =~ m/([^.]+)$/)[0];
		print "Info: Found '$ext' extension for the given script.\n";
	} else {
		$ext = $self -> {'ext'};
	}

	my $gist = WWW::GitHub::Gist -> new(
		user	=> $login,
		token	=> $token
	);

	$gist -> add_file($basename, $data, $ext);
	my $repo = $gist -> create -> {'repo'};

	return $repo;
}

=head1 AUTHOR

Alessandro Ghedini <alexbio@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Alessandro Ghedini.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of App::gist

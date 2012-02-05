package App::gist;

use File::Basename;
use WWW::GitHub::Gist::v3;

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

    say 'Created gist: '.App::gist -> new($file) -> run;

=head1 METHODS

=head2 new( $file )

Create a App::gist object using the given file and its extension.

=cut

sub new {
	my ($class, $args, $file) = @_;

	my $login	= $ENV{GITHUB_USER}   || `git config github.user`;
	my $token	= $ENV{GITHUB_PASSWD} || `git config github.password`;

	chomp $login; chomp $token;

	my ($name, $data);

	if ($file) {
		open my $fh, '<', $file or die "Err: Enter a valid file name.\n";
		$data = join('', <$fh>);
		close $fh;

		$name = basename($file);
	} else {
		$name = 'gistfile.txt';
		$data = join('', <STDIN>);
	}

	my $opts = {
		'name'        => $name,
		'data'        => $data,
		'login'       => $login,
		'token'       => $token,
		'gist'        => $args -> {'update'},
		'private'     => $args -> {'private'},
		'description' => $args -> {'description'}
	};

	return bless $opts, $class;
}

=head2 run( )

Just run the app.

=cut

sub run {
	my $self = shift;

	my ($login, $token, $gist);

	my $data = $self -> {'data'};
	my $basename = $self -> {'name'};

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

	if ($self -> {'gist'}) {
		$gist = WWW::GitHub::Gist::v3 -> new(
			id		=> $self -> {'gist'},
			user		=> $login,
			password	=> $token
		);

		return $gist -> edit(
			files => { $basename => $data }
		);
	} else {
		$gist = WWW::GitHub::Gist::v3 -> new(
			user		=> $login,
			password	=> $token
		);

		return $gist -> create(
			description => $self -> {'description'},
			public => $self -> {'private'} ? 0 : 1,
			files => { $basename => $data }
		);
	}
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

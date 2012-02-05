package App::gist;

use File::Basename;
use WWW::GitHub::Gist::v3;

use strict;
use warnings;

=head1 NAME

App::gist - GitHub Gist creator

=head1 SYNOPSIS

    use feature 'say';
    use App::gist;

    use strict;
    use warnings;

    say 'Created gist: ' . App::gist -> new($file) -> run;

=head1 METHODS

=head2 new( $file )

Create a App::gist object using the given file.

=cut

sub new {
	my ($class, $args, $file) = @_;

	my $login	= $ENV{GITHUB_USER}   || `git config github.user`;
	my $passwd	= $ENV{GITHUB_PASSWD} || `git config github.password`;

	chomp $login; chomp $passwd;

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
		'passwd'      => $passwd,
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

	my ($login, $passwd, $gist);

	my $data = $self -> {'data'};
	my $basename = $self -> {'name'};

	if (!$self -> {'login'}) {
		print STDERR "Enter username: ";
		chop($login = <STDIN>);
	} else {
		$login = $self -> {'login'};
	}

	if (!$self -> {'passwd'}) {
		print STDERR "Enter password for '$login': ";
		system('stty','-echo') if $^O eq 'linux';
		chop($passwd = <STDIN>);
		system('stty','echo') if $^O eq 'linux';
		print "\n";
	} else {
		$passwd = $self -> {'passwd'};
	}

	if ($self -> {'gist'}) {
		$gist = WWW::GitHub::Gist::v3 -> new(
			id		=> $self -> {'gist'},
			user		=> $login,
			password	=> $passwd
		);

		return $gist -> edit(
			files => { $basename => $data }
		);
	} else {
		$gist = WWW::GitHub::Gist::v3 -> new(
			user		=> $login,
			password	=> $passwd
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

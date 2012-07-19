package App::gist;

use strict;
use warnings;

use base qw(App::Cmd::Simple);

use File::Basename;
use WWW::GitHub::Gist::v3;
use Class::Load qw(try_load_class);

=head1 NAME

App::gist - GitHub Gist creator

=head1 SYNOPSIS

    use App::gist;

    use strict;
    use warnings;

    App::gist -> run;

=cut

sub opt_spec {
	return (
		["description|d=s", "set the description for the gist"         ],
		["update|u=s",      "update the given gist with the given file"],
		["private|p",       "create a private gist"                    ],
		["quiet|q",         "only output the web url"                  ]
	);
}

sub execute {
	my ($self, $opt, $args) = @_;

	my ($login, $passwd) = $self -> _get_credentials;

	my $id		= $opt -> {'update'};
	my $file	= $args -> [0];
	my $description	= $opt -> {'description'};
	my $public	= $opt -> {'private'} ? 0 : 1;
	my $quiet	= $opt -> {'quiet'} ? 1 : 0;

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

	my $gist = WWW::GitHub::Gist::v3 -> new(
		user		=> $login,
		password	=> $passwd
	);

	my $info = $id					?
		_edit_gist($gist, $id, $name, $data)	:
		_create_gist($gist, $name, $data, $description, $public);


	if ($quiet) {
		print $info -> {'html_url'} . "\n";
 	} else {
		print "Gist " . $info -> {'id'} . " successfully created/modified.\n";
		print "Web URL: " . $info -> {'html_url'} . "\n";
		print "Public Clone URL: " . $info -> {'git_pull_url'} . "\n"
			if $public;
		print "Private Clone URL: " . $info -> {'git_push_url'} . "\n";
	}
}

sub _create_gist {
	my ($gist, $name, $data, $description, $public) = @_;

	return $gist -> create(
		description => $description, public => $public,
		files => { $name => $data }
	);
}

sub _edit_gist {
	my ($gist, $id, $name, $data) = @_;

	$gist -> id($id);

	return $gist -> edit(files => { $name => $data });
}

sub _get_credentials {
	my ($self) = @_;

	my ($login, $pass, $token);

	my %identity = Config::Identity::GitHub -> load
		if try_load_class('Config::Identity::GitHub');

	if (%identity) {
		$login = $identity{'login'};
	} else {
		$login = `git config github.user`;  chomp $login;
	}

	if (!$login) {
		my $error = %identity ?
			"Err: missing value 'user' in ~/.github" :
			"Err: Missing value 'github.user' in git config";

		$self -> log($error);
		return;
	}

	if (%identity) {
		$token = $identity{'token'};
		$pass  = $identity{'password'};
	} else {
		$token = `git config github.token`;    chomp $token;
		$pass  = `git config github.password`; chomp $pass;
	}

	if ($token) {
		$self -> log("Err: Login with GitHub token is deprecated");
		return (undef, undef);
	} elsif (!$pass) {
		require Term::ReadKey;

		print STDERR "Enter password for '$login': ";
		Term::ReadKey::ReadMode('noecho');
		chop($pass = <STDIN>);
		Term::ReadKey::ReadMode('normal');
		print "\n";
	}

	return ($login, $pass);
}

sub log {
	my ($self, $msg) = @_;

	print STDERR "$msg\n";
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

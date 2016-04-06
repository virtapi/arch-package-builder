#!/usr/bin/env perl

# written by Bluewind

use warnings;
use strict;
use Archive::Tar;
use File::Basename;

=pod

=head1 SYNOPSIS

verify-pacman-repo-db.pl <database file>

=head1 DESCRIPTION

Look at a pacman repo database and verify its content with the packages around it.
The database is expected to be in the same directory as the packages (or symlinks to the packages).

Currently only existence and file size is checked.

=cut

sub main {
	my $repodb = shift @ARGV;
	my $errors = 0;

	my $db = Archive::Tar->new();
	warn $db->error() unless $db->read($repodb);

	my @files = $db->list_files();
	for my $file_object ($db->get_files()) {
		if ($file_object->name =~ m/^([^\/]+)\/desc$/) {
			my $package = $1;
			#print "Checking package $package\n";
			my $dbdata = parse_db($file_object->get_content);
			$errors += verify_db_entry(dirname($repodb), $dbdata);
		}
	}

	return $errors > 0;
}

sub parse_db {
	my $content = shift;
	my %db;
	my $key;

	for my $line (split /\n/, $content) {
		if ($line eq '') {
			$key = undef;
			next;
		}
		if ($line =~ m/^%(.+)%$/) {
			$key = $1;
		} else {
			$db{$key} = [] unless $db{$key};
			push @{$db{$key}}, $line;
			die "\$key not set. Is the db formated incorrectly?" unless $key;
		}
	}
	return \%db;
}

sub verify_db_entry {
	my $basedir = shift;
	my $dbdata = shift;
	my $ret = 0;

	#print Dumper($dbdata);
	my $pkgfile = $basedir.'/'.$dbdata->{FILENAME}[0];
	unless (-e $pkgfile) {
		printf STDERR "Package file missing: %s\n", $pkgfile;
		return 1;
	}

	my $csize = $dbdata->{CSIZE}[0];
	my $filesize = (stat($pkgfile))[7];
	unless ($csize == $filesize) {
		printf STDERR "Package file has incorrect size: %d vs %d: %s\n", $csize, $filesize, $pkgfile;
		$ret = 1;
	}

	# TODO verify checksums, gpg sigs

	return $ret;
}

exit main();

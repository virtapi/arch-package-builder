#!/usr/bin/env perl -T

# written by Bluewind

use warnings;
use strict;
use Getopt::Long;
use Pod::Usage;

=pod

=head1 SYNOPSIS

verify-pacman-repo-db.pl <database file> ...

=head1 DESCRIPTION

verify-pacman-repo-db.pl looks at a pacman repo database and verify its content
with the actual package files. The database is expected to be in the same
directory as the packages (or symlinks to the packages).

The following properties are verified:

 - existence of the package file
 - file size
 - MD5 and SHA256 checksum

=head1 NOTES

This script does intentionally not use any ALPM libraries. The format is simple
enough to be parsed and this way we might just detect more problems because the
libalpm parsing code might also have bugs. We also stay much more portable
which might be good for people that want to check a db, but don't actually have
pacman installed.

=cut

package main;
exit main();

sub main {
	my $errors = 0;
	my %opts = (
		threads => 1,
	);

	Getopt::Long::Configure ("bundling");
	pod2usage(-verbose => 0) if (@ARGV== 0);
	GetOptions(\%opts, "help|h", "debug", "threads|t=i") or pod2usage(2);
	pod2usage(0) if $opts{help};

	my $verifier = Verifier->new(\%opts);

	for my $repodb (@ARGV) {
		$errors += $verifier->check_repodb($repodb);
	}

	$verifier->finalize();

	return $errors > 0;
}

package Verifier;
use Archive::Tar;
use Digest::MD5;
use Digest::SHA;
use File::Basename;
use threads;
use Thread::Queue;

sub new {
	my $class = shift;
	my $opts = shift;

	my $self = {
		opts => \%{$opts},
		package_queue => Thread::Queue->new(),
		output_queue => Thread::Queue->new(),
		workers => [],
		errors => 0,
	};

	bless $self, $class;

	for (my $i = 0; $i < $opts->{threads}; $i++) {
		my $thr = threads->new(sub {
				while (my $workpack = $self->{package_queue}->dequeue()) {
					$self->{output_queue}->enqueue(sprintf("Thread %s: Checking package %s\n", threads->self->tid(), $workpack->{package})) if $self->{opts}->{debug};
					my $dbdata = $self->parse_db($workpack->{db_desc_content});
					$self->{errors} += $self->verify_db_entry($workpack->{dirname}, $dbdata);
				}
			});
		push @{$self->{workers}}, $thr;
	}

	threads->new(sub {
			while (my $output = $self->{output_queue}->dequeue()) {
				print STDERR $output;
			}
		});

	return $self;
}

sub finalize {
	my $self = shift;

	$self->{package_queue}->end();

	# wait for everyone before exiting
	foreach my $thr (@{$self->{workers}}) {
		if ($thr->tid && !threads::equal($thr, threads->self)) {
			print "waiting for thread ".$thr->tid()." to finish\n" if $self->{opts}->{debug};
			$thr->join;
		}
	}

	$self->{output_queue}->end();

	foreach my $thr (threads->list) {
		if ($thr->tid && !threads::equal($thr, threads->self)) {
			print "waiting for thread ".$thr->tid()." to finish\n" if $self->{opts}->{debug};
			$thr->join;
		}
	}
}

sub check_repodb {
	my $self = shift;
	my $repodb = shift;

	$self->{output_queue}->enqueue(sprintf("Checking database '%s'\n", $repodb));

	my $db = Archive::Tar->new();
	$db->read($repodb);

	my $dirname = dirname($repodb);

	my @files = $db->list_files();
	for my $file_object ($db->get_files()) {
		if ($file_object->name =~ m/^([^\/]+)\/desc$/) {
			my $package = $1;
			$self->{package_queue}->enqueue({
					package => $package,
					db_desc_content => $file_object->get_content(),
					dirname => $dirname,
				});
		}
	}
}

sub parse_db {
	my $self = shift;
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
			push @{$db{$key}}, $line;
			die "\$key not set. Is the db formated incorrectly?" unless $key;
		}
	}
	return \%db;
}

sub verify_db_entry {
	my $self = shift;
	my $basedir = shift;
	my $dbdata = shift;
	my $ret = 0;
	my $output = "";

	#print Dumper($dbdata);

	# verify package exists
	my $pkgfile = $basedir.'/'.$dbdata->{FILENAME}[0];
	unless (-e $pkgfile) {
		$output .= sprintf "Package file missing: %s\n", $pkgfile;
		return 1;
	}

	# verify package has correct file size
	my $csize = $dbdata->{CSIZE}[0];
	my $filesize = (stat($pkgfile))[7];
	unless ($csize == $filesize) {
		$output .= sprintf "Package file has incorrect size: %d vs %d: %s\n", $csize, $filesize, $pkgfile;
		$ret = 1;
	}

	# verify checksums
	my $md5 = Digest::MD5->new;
	my $sha = Digest::SHA->new(256);
	# 128MiB to keep random IO low when using threads
	my $chunksize = 1024*1024*128;
	my $content;
	open my $fh, "<", $pkgfile;
	while (read($fh, $content, $chunksize)) {
		$md5->add($content);
		$sha->add($content);
	}

	my $expected_sha = $dbdata->{SHA256SUM}[0];
	my $expected_md5 = $dbdata->{MD5SUM}[0];
	my $got_md5 = $md5->hexdigest;
	my $got_sha = $sha->hexdigest;

	unless ($expected_sha eq $got_sha and $expected_md5 eq $got_md5) {
		$output .= sprintf "Package file has incorrect checksum: %s\n", $pkgfile;
		$output .= sprintf "expected: SHA %s\n", $expected_sha;
		$output .= sprintf "got:      SHA %s\n", $got_sha;
		$output .= sprintf "expected: MD5 %s\n", $expected_md5;
		$output .= sprintf "got:      MD5 %s\n", $got_md5;
		$ret = 1;
	}

	# TODO verify gpg sigs?

	$self->{output_queue}->enqueue($output) if $output ne "";

	return $ret;
}


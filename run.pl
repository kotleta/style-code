#! /usr/bin/perl

use strict;
use warnings;

use Perl::Tidy;
use Getopt::Long;
my $display_help;
my $verbose = 0;

GetOptions(
    'verbose|v' => \$verbose,
    'help'      => \$display_help,
);

if ($display_help) {
    print "perl ./scripts/perltidy/run.pl [--help] [dir1 file1 file2 ...]
    --help\t- show this message;
    --verbose\t- print success;

    dir\t- the directory where preltidy will apply for each *.pl, *.pm and *.t recursively;
    file\t- the file for preltidy will apply for this (*.pl, *pm, *.t);
    ";
    exit(0);
}

if (@ARGV) {
    my @files = @ARGV;
    @ARGV = ();
    for my $file (@files) {
        if ( -d $file ) {
            find_and_apply($file);
        } elsif ( -e $file ) {
            perltidy_apply($file) if $file =~ /\.(?:p[lm]|t)$/;
        } else {
            warn("$file doesn't exist");
        }
    }
} else {
    find_and_apply("./");
}

sub find_and_apply {
    my $dir = shift;
    opendir( my $dh, $dir ) || die "Cann't open `$dir` dir: $!";
    while ( readdir $dh ) {
        next if $_ =~ /^\./;
        next if $_ =~ /^tmp_/;
        my $file_to_apply = "$dir/$_";
        if ( -d $file_to_apply ) {
            find_and_apply($file_to_apply);
        } elsif ( $_ =~ /\.(?:p[lm]|t)$/ ) {
            perltidy_apply($file_to_apply);
        }
    }
    close($dir);
}

sub perltidy_apply {
    my $file = shift;
    my $err_string;
    my $dest_string;
    my $errorfile_string;
    my $error = Perl::Tidy::perltidy(
        source      => $file,
        perltidyrc  => "./scripts/perltidy/rc",
        stderr      => \$err_string,
        destination => \$dest_string,
        errorfile   => \$errorfile_string,
    );
    if ( $error or $err_string ) {
        warn("$file: $err_string");
    } else {
        open( my $fh, '>', $file ) or die "Can't open file '$file' $!";
        print $fh $dest_string;
        close($fh);
        print "$file done\n" if $verbose;
    }
}

1;

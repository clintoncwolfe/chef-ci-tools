#!/usr/bin/env perl
use warnings;
use strict;
use Getopt::Long;
use v5.12;

# This is used by anything that does ruby syntax checks - specifically:
#  ruby -wc
#  erb -xT - file.erb | ruby -wc


# ruby-wc outputs:
# Syntax OK (STDOUT)
# or
# roles/jenkins-server.rb:24: warning: possibly useless use of a literal in void context
# roles/jenkins-server.rb:24: syntax error, unexpected tASSOC, expecting $end
# :authorization => {
#                 ^
# (to STDERR)

# Only first hard error is reported, then check is aborted.
# HArd errors give an exit value of 1, syntax OK 0, and syntax OK with warnings 0.

# So, our plan here is just to watch STDIN, and we count warnings and errors.  If 0, we assume pass; otherwise, we try to categorize warnings and errors.

# So, assuming we are invoked like this:
# ruby -wc roles/$rolefile 2>&1 | ruby-syntax2junit.pl --suite $rolefile --class $rolefile --out junit_reports/roles-syntax-check-$rolefile.xml

# The --class and --suite options control how Jenkins aggregrates the pages in the report.  May take some tweaking.

# For a fascinating guide on how jenkins interprets this file, see
# http://nelsonwells.net/2012/09/how-jenkins-ci-parses-and-displays-junit-output/


my $time = localtime();

my %opts;
GetOptions(
           'class=s' => \$opts{class},
           'suite=s' => \$opts{suite},
           'out=s' => \$opts{out},
          );


my @warnings = ();
my $error = '';

while (my $line = <>) {
    # echo $line to stdout
    print $line;

    if ($error) {
        # We've already started seeing an error - assume all following lines are a continuation of the error message.
        $error .= $line;
    } else {
        # Try to detect if we are seeing a warning, an error, or what
        if ($line eq "Syntax OK\n") {
            # nope
            next;
        } elsif ($line =~ /warning:/) {
            # Warnings have a consistent 'warning:' prefix and *seem* to always be one line
            push @warnings, $line;
        } else {
            # errors don't have a consistent prefix, but are showstoppers, so there will only be one.
            $error = $line;
        }
    }
}

my $out;
open($out, ">$opts{out}") || die "Could not open $opts{out}: $!";

print $out <<EOX;
<?xml version="1.0" encoding="UTF-8"?>
<testsuites>
  <testsuite name="$opts{suite}" timestamp="$time">
  <testcase classname="RolesRubySyntax.$opts{class}" name="$opts{class}">;
EOX

foreach my $warning (@warnings) {
    print $out qq{<failure type="warning">\n};
    print $out qq{<![CDATA[$warning]]>\n};
    print $out qq{</failure>\n};
}

if ($error) {
    print $out qq{<failure type="syntax-error">\n};
    print $out qq{<![CDATA[$error]]>\n};
    print $out qq{</failure>\n};
}

print $out <<EOX;
    </testcase>
  </testsuite>
</testsuites>
EOX

close $out;

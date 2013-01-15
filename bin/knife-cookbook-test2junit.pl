#!/usr/bin/env perl
use warnings;
use strict;
use Getopt::Long;
use v5.12;


# knife cookbook test <cookbook> seems to output:

# checking <cookbook>
# Running syntax check on <cookbook>
# Validating ruby files
# Validating templates
# FATAL: Erb template templates/default/knife.rb.erb has a syntax error:
# FATAL: -:18: syntax error, unexpected '}', expecting ']'
# FATAL: '; foo[ } 
# FATAL:          ^

# Only first error is reported.  If a ruby file has an error, the templates are not checked.
# Exit value is 1 on error, 0 on clear.

# So, our plan here is just to watch STDIN, and if we see FATAL:, we assume it is a failure.

# So, assuming we are invoked like this:
# knife cookbook test $cbook 2>&1 | knife-cookbook-test2junit.pl --suite $cbook --out knife-cookbook-test-$cbook.xml

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


my $error = '';

while (my $line = <>) {
    # echo $line to stdout
    print $line;
    if ($line =~ /^FATAL:/) {
        $error .= $line;
    }
}

my $out;
open($out, ">$opts{out}") || die "Could not open $opts{out}: $!";

print $out <<EOX;
<?xml version="1.0" encoding="UTF-8"?>
<testsuites>
  <testsuite name="$opts{suite}" timestamp="$time">
  <testcase classname="RubyCookbookSyntax.$opts{class}" name="$opts{class}">;
EOX

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

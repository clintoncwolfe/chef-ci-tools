#!/usr/bin/env perl
use warnings;
use strict;
use Getopt::Long;
use v5.12;

# jsonlint -v *.json seems to operate as follows:
# if file OK, one line to STDOUT in form <filename>: ok
# if file not OK, one line to STDERR in form <filename>: <error> .  Only first error is reported.
# If multiple files are specified, each file is processed, even if earlier files are bad.

# So, assuming we are invoked like this:
# jsonlist -v *.json 2>&1 | jsonlint2perl.pl --class some-grouping --suite some-grouping --out jsonlint-report.xml

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

my $out;
open($out, ">$opts{out}") || die "Could not open $opts{out}: $!";


print $out <<EOX;
<?xml version="1.0" encoding="UTF-8"?>
<testsuites>
  <testsuite name="$opts{suite}" timestamp="$time">
EOX

while (my $line = <>) {
    # Echo input
    print $line;
    my ($filename, $message) = $line =~ /(.+?):\s(.+)\n/;
    print $out qq{<testcase classname="JsonLint.$opts{class}" name="$filename">\n};
    if ($message ne 'ok') {
        my $category = categorize_error($message);
        print $out qq{<failure type="$category">\n};
        print $out qq{<![CDATA[$message]]>\n};
        print $out qq{</failure>\n};
    }
    print $out "</testcase>\n";
}
print $out <<EOX;
  </testsuite>
</testsuites>
EOX

close $out;

sub categorize_error {
    my $msg = shift;
    my $type;
    foreach ($msg) {
        when (/unknown keyword or identifier/) { $type = 'BareString' }
        when (/strict JSON does not allow a final comma/) { $type = 'TrailingComma' }
        when (/string literals must use double quotation marks/) { $type = 'MustUseDoubleQuotes' }
        default   { $type = 'Other' }
    }
    return $type;
}



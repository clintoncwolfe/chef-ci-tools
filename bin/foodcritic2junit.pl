#!/usr/bin/env perl
use warnings;
use strict;
use Getopt::Long;
use v5.12;

# assuming we are invoked like this:
# foodcritic cookbooks/$cookbook | foodcritic2perl.pl --suite $cookbook  --out foodcritic-$cookbook.xml

# Foodcritic outputs lines like this:
# foodcritic cookbooks/ca-cron/
# FC045: Consider setting cookbook name in metadata: cookbooks/ca-cron/metadata.rb:1

# The -C option is not useful, unless you are under a color terminal.

# I've decided to hardcode the number of known rules here, and then
# treat each cookbook as a "class", and each rule as a single test.  So multiple
# violations of a rule within a cookbook count as one failure.
# This gives us a predictable number of tests.

# For a fascinating guide on how jenkins interprets JUNIT file, see
# http://nelsonwells.net/2012/09/how-jenkins-ci-parses-and-displays-junit-output/


#------------------------------------------------------------#
#                  FC Rule Counts
#------------------------------------------------------------#

my $FOODCRITIC_RULE_COUNT = 51;
my @DEPRECATED_RULES = ( 1, 20, 35);
my %MESSAGES_BY_RULE = (); # autopopulate as needed
my %VIOLATIONS_BY_RULE = map { sprintf('FC%03d', $_) => [] } (1..$FOODCRITIC_RULE_COUNT);
for (@DEPRECATED_RULES) {
    delete $VIOLATIONS_BY_RULE{sprintf('FC%03d', $_)};
}

# print join("\n", sort keys %VIOLATIONS_BY_RULE);


#------------------------------------------------------------#
#                 Read Options
#------------------------------------------------------------#

my %opts;
GetOptions(
           'suite=s' => \$opts{suite},
           'out=s'   => \$opts{out},
          );


#------------------------------------------------------------#
#                Parse FC Output
#------------------------------------------------------------#

while (my $line = <>) {
    chomp $line;
    my ($rule, $message, $filename, $lineno) = $line =~ /([A-Z]+\d+?):\s(.+?):\s(.+):(\d+)$/;
    if (!$line) {
        # Skip blank
    } elsif ($line =~ /\[DEPRECATION\]/) {
        # Ignore noisy ruby decprecation warnings
    } elsif (!$rule) {
        print "Unparseable foodcritic output: $line\n";
    } elsif (exists $VIOLATIONS_BY_RULE{$rule}) {
        print $line . "\n";  # Echo FC output
        push @{$VIOLATIONS_BY_RULE{$rule}}, "$filename:$lineno";
        $MESSAGES_BY_RULE{$rule} = $message;
    } else {
        print "ignoring in junit - " . $line . "\n"; # Echo FC output
    }
}

#------------------------------------------------------------#
#                Output JUNIT XML
#------------------------------------------------------------#

my $out;
open($out, ">$opts{out}") || die "Could not open $opts{out}: $!";

print $out <<EOX;
<?xml version="1.0" encoding="UTF-8"?>
<testsuites>
  <testsuite name="$opts{suite}" timestamp="">
EOX

foreach my $rule (sort keys %VIOLATIONS_BY_RULE) {
    print $out qq{<testcase classname="FoodCritic.$rule" name="$opts{suite}">\n};
    my @violations = @{$VIOLATIONS_BY_RULE{$rule}};
    foreach my $violation (@violations) {
        print $out qq{<failure type="$MESSAGES_BY_RULE{$rule}">\n};
        print $out qq{$MESSAGES_BY_RULE{$rule}: $violation\n};
        print $out qq{</failure>\n};
    }
    print $out "</testcase>\n";
}
print $out <<EOX;
  </testsuite>
</testsuites>
EOX

close $out;

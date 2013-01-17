chef-ci-tools
=============

Glue scripts to assist testing chef cookbooks under Jenkins (and other CI engines).

## What it Does

This kit tries to fill in some of the gaps between the various chef cookbook testing tools (like foodcritic, etc) and your continuous integration environment.

Currently, we can only do static analysis - no real testing yet.  Stay tuned!

### foodcritic-junit publisher

Runs foodcritic on each of your cookbooks, one by one.  Emits foodcritic output to the console log, but also interprets it, to create an XML report in jUnit format.  Each rule is considered a testcase, and each cookbook a test suite - so multiple rule violations of the same rule in the same cookbook appear as one failure, but at least you get a constant number of tests.

All arguments passed to chef-foodcritic-publisher.sh are passed to foodcritic, like this:

    foodcritic <your-args> cookbook/<a-cookbook>

### jsonlint-junit publisher

Runs jsonlint -v on all files in nodes/ and data_bags.  Emits jsonlint to the console log, but also interprets it, to create an XML report in jUnit format.  Each file is considered a test case.  Tries to interpret the most common errors (trailing comma, unquoted keys, etc).

## What you need

    * A CI server, like Jenkins or Travis.  
    * a foodcritic installation
    * a jsonlint installation   
    * a chef-solo or chef-client installation (we need knife)
    * perl 5.12+ (no CPAN modules needed)

## Maturity

Pre-alpha, extremely immature.  Works in my environment with my toolset, may not in yours.  Pull requests welcome.

## Roadmap

    * testkitchen is the obvious next step, methinks
    * I only use Jenkins, so if someone out there wants to try this with another CI and help me make/keep it portable, I'm open to it.



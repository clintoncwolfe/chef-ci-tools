#!/bin/bash
mkdir -p junit_reports
rm junit_reports/knife-cookbook-test-*.xml 2>/dev/null

if [[ -z "$KNIFE_CONF" ]]; then
    CHEF_CI_TOOLS_DIR="`dirname \"$0\"`"
    KNIFE_CONF="$CHEF_CI_TOOLS_DIR/../etc/knife.rb"
fi

export KNIFE_CONF

source /usr/local/rvm/scripts/rvm
rvm use ruby-1.9.3 2>/dev/null

THE_BUILD_FAILED=0

for cbname in `find cookbooks -maxdepth 1 -mindepth 1 -type d | sed -e 's/cookbooks\///'`; do
  echo "------ cookbook ruby syntax checks: $cbname ------"
  knife cookbook test -c $KNIFE_CONF $cbname | knife-cookbook-test2junit.pl --suite $cbname --class $cbname --out junit_reports/knife-cookbook-test-$cbname.xml
  LAST_ONE_FAILED=${PIPESTATUS[0]}
  if [[ $LAST_ONE_FAILED -ne 0 ]]; then
      THE_BUILD_FAILED=$LAST_ONE_FAILED
  fi;
done

exit $THE_BUILD_FAILED

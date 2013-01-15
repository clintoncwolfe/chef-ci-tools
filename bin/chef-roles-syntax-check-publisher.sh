#!/bin/bash
mkdir -p junit_reports
rm junit_reports/roles-syntax-check-*.xml 2>/dev/null

source /usr/local/rvm/scripts/rvm
rvm use ruby-1.9.3 2>/dev/null

THE_BUILD_FAILED=0

for rolefile in `find roles -maxdepth 1 -mindepth 1 -name '*.rb' | sed -e 's/roles\///'`; do
  echo "------ roles ruby syntax checks: $rolefile ------"
  role=`basename $rolefile .rb`
  ruby -wc roles/$rolefile 2>&1 | ruby-syntax2junit.pl --suite $role --class $role --out junit_reports/roles-syntax-check-$role.xml
  LAST_ONE_FAILED=${PIPESTATUS[0]}
  if [[ $LAST_ONE_FAILED -ne 0 ]]; then
      THE_BUILD_FAILED=$LAST_ONE_FAILED
  fi;
done

exit $THE_BUILD_FAILED

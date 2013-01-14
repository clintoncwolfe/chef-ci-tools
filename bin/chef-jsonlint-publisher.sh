#!/bin/bash
mkdir -p junit_reports
rm junit_reports/jsonlint-*.xml 2> /dev/null
if ls nodes/*.json > /dev/null 2>&1; then
  echo "------ jsonlint checks: nodes ------"
  jsonlint -v nodes/*.json 2>&1 | jsonlint2junit.pl --class Nodes --suite Nodes --out junit_reports/jsonlint-nodefiles.xml
fi
if ls data_bags/*/*.json > /dev/null 2>&1; then
  echo "------ jsonlint checks: data_bags ------"
  jsonlint -v data_bags/*/*.json 2>&1 | jsonlint2junit.pl --class DataBags --suite DataBags --out junit_reports/jsonlint-databags.xml
fi

require 'fileutils'


FileUtils.mkpath('test/reports')
FileUtils.rm_f Dir.glob('test/reports/foodcritic-*.xml')

cbname = File.basename(Dir.pwd)
puts "------ foodcritic checks: #{cbname} ------"


rule_counts = { 'FC' => 45, 'ZOS' =>  17, 'ETSY' => 7 }   # TODO: place into command line args or config file
deprecated_rules = %w(FC001 FC020 FC035 ETSY002 ETSY003 ZOS006 ) # TODO: place into command line args or config file

rule_names = []
rule_counts.each do |prefix, count| 
  rule_names += 1.upto(count).map { |n| format(prefix + '%03d', n) }  
end
rule_names -= deprecated_rules

messages_by_rule = {} # autopopulate as needed
violations_by_rule = {} 
rule_names.each {|r| violations_by_rule[r] = [] }

#------------------------------------------------------------#
#                Parse FC Output
#------------------------------------------------------------#

ARGF.each_line do |fcline|

  # Foodcritic outputs lines like this:
  # foodcritic cookbooks/ca-cron/
  # FC045: Consider setting cookbook name in metadata: cookbooks/ca-cron/metadata.rb:1

  # I've decided to hardcode the number of known rules here, and then
  # treat each cookbook as a "class", and each rule as a single test.  So multiple
  # violations of a rule within a cookbook count as one failure.
  # This gives us a predictable number of tests.


  # For a fascinating guide on how jenkins interprets JUNIT file, see
  # http://nelsonwells.net/2012/09/how-jenkins-ci-parses-and-displays-junit-output/

  fcline.chomp 
  m = fcline.match(/(?<rule>[A-Z]+\d+?):\s(?<message>.+?):\s(?<filename>.+):(?<lineno>\d+)$/)
  
  if (fcline.match(/^\s*$/)) then
    # Skip blank
  elsif (fcline =~ /\[DEPRECATION\]/) then
    # Ignore noisy ruby decprecation warnings
  elsif (!m) then
    puts "Unparseable foodcritic output: #{fcline}"
  elsif (violations_by_rule.has_key?(m[:rule])) then
    puts fcline  # Echo FC output
    violations_by_rule[m[:rule]].push m[:filename] + ':' + m[:lineno]
    messages_by_rule[m[:rule]] = m[:message]
  else
    puts "ignoring in junit - " + fcline  # Echo FC output
  end

end


#------------------------------------------------------------#
#                Output JUNIT XML
#------------------------------------------------------------#

File.open('test/reports/foodcritic-' + cbname + '.xml', 'w') do |out|
  out.print <<-EOX
<?xml version="1.0" encoding="UTF-8"?>
<testsuites>
  <testsuite name="#{cbname}" timestamp="">
EOX

  #violations_by_rule.keys.sort do |rule|
  violations_by_rule.keys.each do |rule|
    out.puts '<testcase classname="FoodCritic.' + rule + '" name="' + cbname + '">'
    violations_by_rule[rule].each do |violation|
        out.puts '<failure type="' + messages_by_rule[rule] + '">'
        out.puts messages_by_rule[rule] + ':' + violation
        out.puts '</failure>'
    end
    out.puts '</testcase>'
  end

  out.puts '  </testsuite>'
  out.puts '</testsuites>'
end

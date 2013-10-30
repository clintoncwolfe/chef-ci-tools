require 'fileutils'

report_file = ARGV.shift

FileUtils.rm_f report_file

puts "------ rspec checks: #{report_file} ------"

#------------------------------------------------------------#
#                Read rspec output
#------------------------------------------------------------#

in_junit = false

File.open(report_file, 'w') do |junit_out|
  ARGF.each_line do |line|

    # This relies on the rspec_junit_formatter gem, and calling
    # rspec like this:
    # rspec -f d -r rspec_junit_formatter -f RspecJunitFormatter
    # rspec will then stream the doc format first, followed by the junit format.  
    # Supposedly this should work (negating the need for this tee script):
    # rspec -f d -r rspec_junit_formatter -f RspecJunitFormatter:some/file.xml
    # but rspec-core v2.14 (and others?) does not respect the colon.
    
    # For a fascinating guide on how jenkins interprets JUNIT file, see
    # http://nelsonwells.net/2012/09/how-jenkins-ci-parses-and-displays-junit-output/

    if line.start_with?('<?xml') then
      in_junit = true
    end

    if in_junit then
      # Send junit XML to report file
      junit_out.print line
    else
      # Send doc format to STDOUT
      print line
    end

  end
end


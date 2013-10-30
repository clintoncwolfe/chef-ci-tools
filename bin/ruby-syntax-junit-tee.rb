require 'fileutils'

rb_file = ARGV.shift
rb_file_scrubbed = rb_file.gsub(/\//, '_')

FileUtils.mkpath('test/reports')
FileUtils.rm_f Dir.glob('test/reports/ruby-syntax-' + rb_file_scrubbed + '.xml')

puts "------ ruby syntax checks: #{rb_file} ------"

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
# Hard errors give an exit value of 1, syntax OK 0, and syntax OK with warnings 0.

# So, our plan here is just to watch STDIN, and we count warnings and errors.  If 0, we assume pass; otherwise, we try to categorize warnings and errors.

# So, assuming we are invoked like this:
# ruby -wc roles/$rolefile 2>&1 | ruby-syntax2junit.pl $file

# For a fascinating guide on how jenkins interprets this file, see
# http://nelsonwells.net/2012/09/how-jenkins-ci-parses-and-displays-junit-output/


warnings = []
error = nil

ARGF.each_line do |line|
  line.chomp

  puts line  # tee output

  if (error) then
    # We've already started seeing an error - assume all following lines are a continuation of the error message.
    error += line + "\n"
  else 
    # Try to detect if we are seeing a warning, an error, or what
    if (line.match(/Syntax OK/)) then
      # nope
      next
    elsif (line.match(/warning:/)) then
      # Warnings have a consistent 'warning:' prefix and *seem* to always be one line
      warnings.push(line)
    else 
      # errors don't have a consistent prefix, but are showstoppers, so there will only be one.
      error = line
    end
  end
end



#------------------------------------------------------------#
#                Output JUNIT XML
#------------------------------------------------------------#

File.open('test/reports/ruby-syntax-' + rb_file_scrubbed + '.xml', 'w') do |out|
  out.print <<-EOX
<?xml version="1.0" encoding="UTF-8"?>
<testsuites>
  <testsuite name="#{rb_file}" timestamp="">
  <testcase classname="RolesRubySyntax.#{rb_file_scrubbed}" name="#{rb_file_scrubbed}">;
EOX

  warnings.each do |warning|
    out.puts '<failure type="warning">'
    out.puts "<![CDATA[#{warning}]]>"
    out.puts '</failure>'
  end

  if (error) then 
    out.puts '<failure type="syntax-error">'
    out.puts "<![CDATA[#{error}]]>"
    out.puts '</failure>'
  end


  out.puts '    </testcase>'
  out.puts '  </testsuite>'
  out.puts '</testsuites>'
end





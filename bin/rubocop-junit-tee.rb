require 'fileutils'
require 'json'

FileUtils.rm_f 'test/reports/rubocop.xml'

cbname = File.basename(Dir.pwd)
puts "------ rubocop checks: #{cbname} ------"

#==================================================#
# Obtain list of enabled Cops from rubocop, using config passed in.
#==================================================#
rubocop_config_file = ARGV.shift

cops = {}
current_type = nil
current_cop = nil
current_desc = nil
`rubocop -c #{rubocop_config_file} --show-cops`.each_line do |line|

  if md = line.match(/^Type '(?<type>.+)'/) then
    current_type = md[:type]
    next
  end

  if md = line.match(/^\s-\s(?<cop>\S+)/) then
    current_cop = md[:cop]
    next
  end

  if md = line.match(/^\s{4}-\sDescription:\s(?<desc>.+)$/) then
    current_desc = md[:desc]
  end

  if md = line.match(/^\s{4}-\sEnabled:\s(?<enabled>true|false)/) then
    if md[:enabled] == 'true' then
      cops[current_cop] = {
        :desc => current_desc,
        :type => current_type,
        :offences => [],
      }
    end
  end
end

#------------------------------------------------------------#
#                Parse RC Output
#------------------------------------------------------------#

json_string = ARGF.read
cop_data = ::JSON.parse(json_string)

cop_data["files"].each do |file_info|

  # make file path relative
  path = file_info["path"].sub(Dir.pwd + '/', '')

  file_info["offences"].each do |offence|

    # Produce a line like -f emacs, it's simple
    tee_line  = path 
    tee_line += ':' + offence["location"]["line"].to_s
    tee_line += ':' + offence["location"]["column"].to_s
    tee_line += ': ' + offence["severity"][0].upcase
    tee_line += ': ' + offence["message"]
    puts tee_line

    # Record the offense per-cop
    cops[offence["cop_name"]][:offences].push offence.merge("path" => path)

  end
end

#------------------------------------------------------------#
#                Output JUNIT XML
#------------------------------------------------------------#

File.open('test/reports/rubocop.xml', 'w') do |out|
  out.print <<-EOX
# <?xml version="1.0" encoding="UTF-8"?>
<testsuites>
  <testsuite name="#{cbname}" timestamp="">
EOX

  cops.each do |name, info|    
    out.puts '<testcase classname="rubocop.' + name + '" name="' + cbname + '">'
    info[:offences].each do |offence|
      out.puts '<failure type="' + name + '">'
      out.puts offence["path"] + ', line ' + offence["location"]["line"].to_s + ', col ' + offence["location"]["column"].to_s
      out.puts '</failure>'
    end
    out.puts '</testcase>'
  end

  out.puts '  </testsuite>'
  out.puts '</testsuites>'
end

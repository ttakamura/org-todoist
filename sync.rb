require 'bundler'
Bundler.require
Dotenv.load

$LOAD_PATH << File.dirname(__FILE__) + "/lib"
require 'org_todoist'
OrgTodoist.configure

infile  = ARGV.shift
outfile = ARGV.shift || infile

sync = OrgTodoist::Sync.new(infile, outfile)

if OrgTodoist.debug?
  byebug
  binding.pry
else
  sync.sync!
  puts "Success Sync!"
end

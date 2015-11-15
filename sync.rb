require 'bundler'
Bundler.require
Dotenv.load

require 'org_todoist'
OrgTodoist.configure

infile  = ARGV.shift
outfile = ARGV.shift || infile

sync = OrgTodoist::Sync.new(infile, outfile)

if ENV['DEBUG']
  byebug
  binding.pry
else
  sync.sync!
  puts "Success Sync!"
end

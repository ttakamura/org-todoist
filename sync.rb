require 'bundler'
Bundler.require

require 'org_todoist'
OrgTodoist.configure

sync = OrgTodoist::Sync.new(ARGV.shift, ARGV.shift)

if ENV['DEBUG']
  byebug
  binding.pry
else
  sync.sync!
end

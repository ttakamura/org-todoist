require 'bundler'
Bundler.require

require 'org_todoist'
OrgTodoist.configure

sync = OrgTodoist::Sync.new(ARGV.shift, ARGV.shift)

byebug
binding.pry

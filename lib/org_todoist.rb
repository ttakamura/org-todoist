module OrgTodoist
  def self.configure
    @token = ENV["ORG_TODOIST_TOKEN"].chomp
  end

  def self.verbose?
    !!ENV['VERBOSE']
  end

  def self.debug?
    !!ENV['DEBUG']
  end

  def self.token
    @token
  end

  def self.api
    @api ||= OrgTodoist::Api.new(verbose: verbose?)
  end

  def self.db
    @db ||= OrgTodoist::DB.new("db/todoist.yaml")
  end

  def self.calendar
    @calendar ||= OrgTodoist::Calendar.new(ENV['CAL_CLIENT_ID'], ENV['CAL_CLIENT_SEC'], ENV['CALENDAR_ID'])
  end

  def self.uuid
    `uuidgen`.chomp
  end

  def self.logger
    @logger = Logger.new("log/todoist.log")
  end

  module Logging
    def log
      OrgTodoist.logger
    end
  end
end

# monkey-patch
class String
  def mb_width
    each_char.map{|c| c.bytesize == 1 ? 1 : 2}.reduce(0, &:+)
  end
end

require 'org_todoist/model'
require 'org_todoist/api'
require 'org_todoist/db'
require 'org_todoist/calendar'
require 'org_todoist/project'
require 'org_todoist/item'
require 'org_todoist/note'
require 'org_todoist/sync'
require 'org_todoist/converter'

require 'org_format/exporter'
require 'org_format/headline'
require 'org_format/schedule'
require 'org_format/clock_log'

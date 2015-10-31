# -*- coding: utf-8 -*-
module OrgFormat
  class Headline
    include ::OrgFormat::Exporter::SerializeOrgHeadline

    extend Forwardable
    attr_reader :headlines, :tags, :level, :effort_min, :state,
                :scheduled_at, :clock_logs, :properties, :body_lines

    attr_accessor :todoist_obj, :title

    class << self
      def parse_org_file file_name
        parse_org open(file_name, 'r:UTF-8').read
      end

      def parse_org text
        parse_headlines HeadlineTop.new, Orgmode::Parser.new(text).headlines
      end

      private
      def parse_headlines current, headlines
        children = []
        while headlines.first && headlines.first.level > current.level
          line = headlines.shift
          children << parse_headlines(line, headlines)
        end
        self.new current, children
      end
    end

    def initialize top_headline, headlines=[]
      if m = top_headline.headline_text.match(/(IDEA|TODO|DONE|NEXT|FOCUS|WAIT|SOMEDAY) /)
        keyword = m[1]
      else
        keyword = top_headline.keyword
      end
      @self_line    = top_headline
      @state        = keyword
      @title        = top_headline.headline_text.gsub(/(IDEA|TODO|DONE|NEXT|FOCUS|WAIT|SOMEDAY) /, '')
      @level        = top_headline.level
      @tags         = top_headline.tags
      @effort_min   = parse_effort_min top_headline.property_drawer['Effort']
      @properties   = top_headline.property_drawer

      # body
      @scheduled_at = nil
      @clock_logs   = []
      @body_lines   = parse_body_lines top_headline.body_lines

      # children
      @headlines    = headlines
    end

    def done!
      @state = 'DONE'
    end

    def done?
      @state == 'DONE'
    end

    def family_tree
      [self] + headlines.map do |sub|
        sub.family_tree
      end
    end

    def all_sub_headlines
      headlines.map(&:family_tree).flatten
    end

    def action?
      !@state.nil?
    end

    def project?
      !action? && tags.include?('PROJECT')
    end

    def id
      @properties['ID'] ? @properties['ID'].to_i : nil
    end

    def id= id
      @properties['ID'] = id.to_s
    end

    private
    def parse_effort_min effort=nil
      if effort
        effort = effort == '00:60' ? '01:00' : effort
        t = Time.parse(effort)
        t.hour * 60 + t.min
      else
        0
      end
    end

    def parse_body_lines body_lines
      body_lines.map do |body_line|
        case body_line.paragraph_type
        when :metadata
          metadata = parse_metadata_line(body_line)
          case metadata
          when ClockLog
            @clock_logs << metadata
          when Schedule
            @scheduled_at = metadata
          else
            puts "Unknown metadata - #{body_line}"
          end
          nil

        when :list_item
          body_line.to_s

        when :paragraph
          body_line.to_s

        else
          nil
        end
      end.compact
    end

    def parse_metadata_line line
      key, value = line.to_s.split(": ").map{ |v| v.gsub(/(^\s*|\s*$)/, '') }
      case key
      when /CLOCK/
        ClockLog.parse value
      when /SCHEDULED/
        Schedule.new value
      end
    end
  end

  # 最上位を表現する Null オブジェクト
  class HeadlineTop
    def level
      0
    end

    def property_drawer
      {'ID' => nil}
    end

    def tags
      []
    end

    def headline_text
      ""
    end

    def keyword
      nil
    end

    def body_lines
      []
    end
  end
end

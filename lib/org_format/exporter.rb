module OrgFormat
  class Exporter
    module SerializeOrgHeadline
      def to_s
        "#{'*' * level} #{state_to_s}#{title}#{tags_to_s}"
      end

      def state_to_s
        state ? state + ' ' : ''
      end

      def tags_to_s
        return "" if tags.empty?
        tag_text = ":#{tags.join(':')}:"
        padding_size = [(73 - (state_to_s.mb_width + title.mb_width + tag_text.mb_width)), 1].max
        ' ' * padding_size + tag_text
      end

      def schedule_to_s
        return "" if scheduled_at.nil?
        "SCHEDULED: #{ scheduled_at.to_s }"
      end

      def clock_logs_to_s
        return "" if clock_logs.empty?
        text = []
        text << ':LOGBOOK:'
        clock_logs.map do |l|
          text << "CLOCK: #{ l.to_s }"
        end
        text << ':END:'
        text.join("\n")
      end

      def properties_to_s
        return "" if properties.empty?
        text = []
        text << ':PROPERTIES:'
        properties.each do |key, value|
          sep_length = (9 - key.length)
          separator = ' ' * (sep_length < 1 ? 1 : sep_length)
          text << ":#{key}:#{separator}#{value}"
        end
        text << ':END:'
        text.join("\n")
      end

      def body_to_s
        body_lines.map do |line|
          line.to_s
        end.join("\n")
      end
    end

    EMACS_DATE_FORMAT = "%Y-%m-%d %a %H:%M"

    def initialize io=STDOUT
      @io = io
    end

    def print_headline headline
      print_text headline.to_s,            0
      print_text headline.schedule_to_s,   headline.level + 1
      print_text headline.properties_to_s, headline.level + 1
      print_text headline.clock_logs_to_s, headline.level + 1
      print_text headline.body_to_s,       0

      headline.headlines.each do |sub_head|
        print_headline sub_head
      end
    end

    def print_text text, level
      text.split("\n").each do |line|
        print_line line, level
      end
    end

    def print_line line, level=1
      @io.puts "#{ ' ' * level }#{ line }"
    end
  end
end

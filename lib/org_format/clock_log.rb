module OrgFormat
  class ClockLog
    attr_reader :start_time, :end_time

    class << self
      def parse text
        range      = parse_range(text)
        start_time = Time.parse(range[:start_time]) if range[:start_time]
        end_time   = Time.parse(range[:end_time])   if range[:end_time]
        self.new start_time, end_time
      end

      def parse_range text
        # [2014-12-31 Wed 05:44]--[2014-12-31 Wed 06:52] =>  1:08
        if m = text.match(/\[(.+?)\](--\[(.+?)\])?(\s+=>\s+(.+?))?$/)
          all, begin_time, sep, end_time, sep2, span = m.to_a
          {start_time: begin_time, end_time: end_time}
        else
          raise "Cannot parse ClockLog: #{text}"
        end
      end
    end

    def initialize start_time, end_time
      start_time = Time.parse(start_time) if start_time.is_a?(String)
      end_time   = Time.parse(end_time)   if end_time.is_a?(String)
      @start_time = start_time
      @end_time   = end_time
    end

    def to_s
      text = []
      text << '[' + start_time.strftime("%Y-%m-%d %a %H:%M") + ']'
      if end_time
        text << '--[' + end_time.strftime("%Y-%m-%d %a %H:%M")   + ']'
        text << ' =>  ' + span_to_s
      end
      text.join("")
    end

    def span_to_s
      span = (end_time - start_time).to_i
      hour = (span/3600).to_i
      min  = (span/60).to_i  % 60
      sprintf("%s:%02d", hour, min)
    end

    def to_a
      if start_time && end_time
        [start_time, end_time]
      else
        nil
      end
    end
  end
end

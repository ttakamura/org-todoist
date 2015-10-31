module OrgFormat
  class Schedule
    attr_accessor :start_time, :repeat_rule, :effort_sec

    def initialize scheduled_text
      @text        = scheduled_text
      @start_time  = parse_next_start_time scheduled_text
      @repeat_rule = parse_time(scheduled_text)[:repeat]
      end_time     = parse_next_end_time(scheduled_text)
      @effort_sec  = end_time - @start_time if end_time
    end

    def to_s
      # SCHEDULED: <2015-01-17 Sat 15:00-16:00>
      date   = start_time.getlocal.strftime("%Y-%m-%d %a")
      s_time = " #{ start_time.getlocal.strftime('%H:%M') }" if start_time.getlocal.strftime("%H:%M") != '23:59'
      e_time = "-#{ end_time.getlocal.strftime('%H:%M') }"   if end_time
      repeat = " #{ repeat_rule }"                           if repeat_rule
      "<#{date}#{s_time}#{e_time}#{repeat}>"
    end

    def end_time
      return nil unless effort_sec
      start_time + effort_sec
    end

    private
    def parse_next_start_time text
      time = parse_time text
      if time[:start_time]
        Time.parse time[:date] + " " + time[:start_time]
      else
        Time.parse time[:date] + " 23:59"
      end
    end

    def parse_next_end_time text
      time = parse_time text
      if time[:end_time]
        Time.parse time[:date] + " " + time[:end_time]
      end
    end

    def parse_time text
      # <2015-01-17 Sat 14:00-19:40>
      if m = text.match(/^<(\d{4}-\d{2}-\d{2}) [^\s]+ ?(\d{2}:\d{2})?(-(\d{2}:\d{2}))? ?(.+)?>$/)
        all, date, start_time, x, end_time, repeat_rule = m.to_a
        {date: date, start_time: start_time, end_time: end_time, repeat: repeat_rule}
      else
        raise "Cannot parse Schedule: #{text}"
      end
    end
  end
end

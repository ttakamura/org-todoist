module OrgFormat
  class IcalExporter
    def initialize top_org_headline
      @top_headline = top_org_headline
    end

    def add_all_clock_logs
      @top_headline.all_sub_headlines.each do |sub|
        add_clock_logs sub
      end
    end

    def add_clock_logs headline
      headline.clock_logs.each do |log|
        e = Icalendar::Event.new
        e.dtstart     = log.start_time
        e.dtend       = log.end_time
        e.summary     = headline.title
        # e.description = ""
        calendar.add_event(e)
      end
    end

    def to_s
      calendar.to_ical
    end

    private
    def calendar
      @calendar ||= begin
                      cal         = Icalendar::Calendar.new
                      tz          = TZInfo::Timezone.get 'Asia/Tokyo'
                      event_start = DateTime.new 2008, 12, 29, 8, 0, 0
                      timezone    = tz.ical_timezone event_start
                      cal.add_timezone timezone
                      cal
                    end
    end
  end
end

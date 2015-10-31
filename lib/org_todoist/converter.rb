module OrgTodoist
  class Converter
    class << self
      def from_todoist_obj headline, obj
        if obj.is_a?(OrgTodoist::Project)
          OrgTodoist::Converter.from_todoist_project(headline, obj)
        elsif obj.is_a?(OrgTodoist::Item)
          OrgTodoist::Converter.from_todoist_item(headline, obj)
        end
      end

      def from_todoist_project headline, project
        headline.id    = project.id
        headline.title = project.name
      end

      def from_todoist_item headline, item
        headline.id    = item.id
        headline.title = item.content
      end

      def to_todoist_projects top_headline
        projects = []
        top_headline.all_sub_headlines.each do |headline|
          if headline.project?
            current_pj = to_todoist_project(headline, 1)
            headline.todoist_obj = current_pj
            to_todoist_items(headline, current_pj)
            projects << current_pj
          end
        end
        projects
      end

      def to_todoist_items top_headline, current_pj
        top_headline.all_sub_headlines.each do |headline|
          if headline.action?
            item = to_todoist_item(headline, current_pj, (headline.level - top_headline.level))
            headline.todoist_obj = item
            current_pj.items << item
          end
        end
      end

      def to_todoist_project headline, indent
        attrs = {
          "id"           => headline.id,
          "name"         => headline.title,
          "indent"       => indent
        }
        OrgTodoist::Project.find_or_init(attrs)
      end

      def to_todoist_item headline, project, indent
        attrs = {
          "checked"      => (headline.done? ? 1 : 0),
          "id"           => headline.id,
          "content"      => headline.title,
          "indent"       => indent,
          "project"      => project
        }
        if headline.scheduled_at
          attrs['due_date_utc'] = time_todoist_format(headline.scheduled_at.start_time)
        end
        OrgTodoist::Item.find_or_init(attrs)
      end

      def time_todoist_format time
        time.utc.strftime("%Y-%m-%dT%H:%M:%S")
      end
    end
  end
end

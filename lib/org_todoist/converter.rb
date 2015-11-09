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
        top_headline.all_sub_headlines.each_with_index do |headline, item_order|
          if headline.project?
            level   = headline.level - top_headline.level
            project = to_todoist_project(headline, level, item_order+1)
            headline.todoist_obj = project
            to_todoist_items(headline, project)
            projects << project
          end
        end
        projects
      end

      def to_todoist_items top_headline, current_pj
        top_headline.all_sub_headlines.each_with_index do |headline, item_order|
          if headline.action?
            level = headline.level - top_headline.level
            item  = to_todoist_item(headline, current_pj, level, item_order+1)
            headline.todoist_obj = item
            current_pj.items << item
          end
        end
      end

      def to_todoist_project headline, indent, item_order
        attrs = {
          "id"           => headline.id,
          "name"         => headline.title,
          "indent"       => indent,
          "item_order"   => item_order
        }
        OrgTodoist::Project.find_or_init(attrs)
      end

      def to_todoist_item headline, project, indent, item_order
        attrs = {
          "checked"      => (headline.done? ? 1 : 0),
          "id"           => headline.id,
          "content"      => headline.title,
          "indent"       => indent,
          "project"      => project,
          "item_order"   => item_order
        }
        if headline.scheduled_at
          attrs['due_date_utc'] = time_todoist_format(headline.scheduled_at.start_time)
          attrs['date_string']  = attrs['due_date_utc']
        end
        OrgTodoist::Item.find_or_init(attrs)
      end

      def time_todoist_format time
        time.utc.strftime("%Y-%m-%dT%H:%M:%S")
      end
    end
  end
end

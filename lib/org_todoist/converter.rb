module OrgTodoist
  class Converter
    module FromTodoist
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
        headline.tags  = (headline.tags + item.labels.map(&:name)).sort.uniq
      end

      def from_todoist_new_item item
        headline = OrgFormat::Headline.parse_org("** IDEA dummy").headlines.first
        from_todoist_item(headline, item)
        headline
      end
    end

    module FromOrgFormat
      def to_todoist_projects top_headline, current_level=1
        projects = []

        top_headline.headlines.each do |headline|
          if headline.project?
            projects << to_todoist_project(headline, current_level)
            projects << to_todoist_projects(headline, current_level+1)
          else
            projects << to_todoist_projects(headline, current_level)
          end
        end

        projects.flatten.each_with_index do |project, index|
          project.item_order = index+1
        end
      end

      def to_todoist_items top_headline, current_pj, current_level=1
        items = []

        top_headline.headlines.each do |headline|
          if headline.action?
            items << to_todoist_item(headline, current_pj, current_level)
            items << to_todoist_items(headline, current_pj, current_level+1)
          end
        end

        items.flatten.each_with_index do |item, index|
          item.item_order = index+1
        end
      end

      def to_todoist_project headline, indent
        attrs = {
          "id"     => headline.id,
          "name"   => headline.title,
          "indent" => indent
        }

        project = OrgTodoist::Project.find_or_init(attrs)
        headline.todoist_obj = project

        to_todoist_items(headline, project).each do |item|
          project.items << item
        end

        project
      end

      def to_todoist_item headline, project, indent
        attrs = {
          "checked" => (headline.done? ? 1 : 0),
          "id"      => headline.id,
          "content" => headline.title,
          "indent"  => indent,
          "project" => project,
          "tags"    => headline.tags
        }
        if headline.scheduled_at
          attrs['due_date_utc'] = time_todoist_format(headline.scheduled_at.start_time)
          attrs['date_string']  = attrs['due_date_utc']
        end

        item = OrgTodoist::Item.find_or_init(attrs)
        headline.todoist_obj = item

        to_todoist_note headline, item

        item
      end

      def to_todoist_note headline, item
        text = headline.body_lines.join("\n")
        return if text == ""

        if note = item.notes.first
          note.content = text
        else
          item.notes << OrgTodoist::Note.new('content' => text, 'item' => item)
        end
      end
    end

    class << self
      include FromTodoist
      include FromOrgFormat

      private
      def time_todoist_format time
        time.utc.strftime("%Y-%m-%dT%H:%M:%S")
      end
    end
  end
end

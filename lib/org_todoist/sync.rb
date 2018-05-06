module OrgTodoist
  class Sync
    attr_reader :projects, :org_head

    def initialize org_file, out_file, api=OrgTodoist.api
      @api      = api
      @org_file = org_file
      @out_file = out_file
      @projects = []
    end

    def foobar
    end

    def sync!
      pull_todoist
      pull_todoist_completed

      import_org_file
      print_projects_tree if OrgTodoist.verbose?
      debugger            if OrgTodoist.debug?

      push_todoist_projects
      debugger            if OrgTodoist.debug?

      push_todoist_items
      debugger            if OrgTodoist.debug?

      push_todoist_notes
      debugger            if OrgTodoist.debug?

      fetch_todoist_changes
      debugger            if OrgTodoist.debug?

      export_org_file
      true
    end

    def import_org_file
      @org_head = OrgFormat::Headline.parse_org_file(@org_file)
      OrgTodoist::Converter.to_todoist_projects(@org_head).each do |pj|
        @projects << pj
      end
    end

    def print_projects_tree
      @projects.each do |pj|
        puts "* Project level:#{pj.indent}, order:#{pj.item_order} #{ '  '*pj.indent } #{pj.name}"
        pj.items.each do |it|
          puts "- Action level:#{it.indent}, order:#{it.item_order} #{ '  '*(pj.indent + it.indent) } #{it.content}"
        end
      end
    end

    def pull_todoist
      @api.pull
    end

    def pull_todoist_completed
      items = {}
      res = @api.get_all_completed_items
      res.body['items'].each do |item|
        items[item['id']] = item
      end
      OrgTodoist::Converter.append_completed_items items
    end

    def push_todoist_projects
      @projects.each do |pj|
        pj.save! @api
      end
      @api.push
    end

    def push_todoist_items
      @projects.each do |pj|
        pj.items.each do |itm|
          itm.save! @api
        end
      end
      @api.push
    end

    def push_todoist_notes
      @projects.each do |pj|
        pj.items.each do |itm|
          itm.notes.each do |note|
            note.save! @api
          end
        end
      end
      @api.push
    end

    def fetch_todoist_changes
      # Update
      org_headlines = @org_head.all_sub_headlines
      org_inbox     = @org_head.headlines.first

      org_headlines.each do |headline|
        if obj = headline.todoist_obj
          OrgTodoist::Converter.from_todoist_obj(headline, obj)
        end
      end

      # Create (inbox)
      todoist_inbox = OrgTodoist::Project.records.values.find{|pj| pj.name == "Inbox"}
      todoist_inbox.items.each do |item|
        unless org_headlines.find{ |h| h.id.to_s == item.id.to_s }
          org_inbox.headlines << OrgTodoist::Converter.from_todoist_new_item(item)
        end
      end
    end

    def export_org_file
      open(@out_file, 'w') do |file|
        expt = OrgFormat::Exporter.new(file)
        @org_head.headlines.each do |headline|
          expt.print_headline(headline)
        end
      end
    end
  end
end

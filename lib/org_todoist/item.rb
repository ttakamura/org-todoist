# coding: utf-8
module OrgTodoist
  class Item < Model
    attribute :id
    attribute :content
    attribute :project_id
    attribute :indent
    attribute :item_order

    def initialize raw_item={}
      raw_item['indent']     ||= 1
      raw_item['item_order'] ||= (self.class.records.last_item_order + 1)
      @project  = raw_item.delete('project')
      @children = []
      super(raw_item)
    end

    def create! api
      @raw['project_id'] = @project.id
      api.reserve 'item_add', self, to_args
    end

    def update! api
      api.reserve 'item_update', self, to_args
    end

    def destroy! api
      raise 'Not persisted' unless persisted?
      api.reserve 'item_delete', self, {'ids' => [id]}
    end

    def todoist_safe_key
      @todoist_safe_key ||= %w(id content priority checked
                               due_date_utc date_string
                               item_order indent collapsed project_id)
    end
  end
end

#> [{"due_date"=>nil,
# "day_order"=>-1,
# "assigned_by_uid"=>138318,
# "due_date_utc"=>nil,
# "is_archived"=>0,
# "labels"=>[],
# "sync_id"=>nil,
# "in_history"=>0,
# "date_added"=>"Sun 01 Nov 2015 11:36:29 +0000",
# "checked"=>0,
# "date_lang"=>"en",
# "id"=>173512497,
# "content"=>"BB",
# "indent"=>1,
# "user_id"=>138318,
# "is_deleted"=>0,
# "priority"=>1,
# "item_order"=>2,
# "responsible_uid"=>nil,
# "project_id"=>154672310,
# "collapsed"=>0,
# "date_string"=>""},

# coding: utf-8
module OrgTodoist
  class Project < Model
    attr_reader :items
    attribute :id
    attribute :name
    attribute :indent
    attribute :item_order

    def initialize raw_project={}
      raw_project['indent']     ||= 1
      raw_project['item_order'] ||= (self.class.records.last_item_order + 1)
      @children = []
      @items    = Item.top.parse_tree(raw_project['items'])
      super(raw_project)
    end

    def item_order= new_order
      @raw['item_order'] = new_order
    end

    def create! api
      api.reserve 'project_add', self, to_args
    end

    def update! api
      api.reserve 'project_update', self, to_args
    end

    def destroy! api
      raise 'Not persisted' unless persisted?
      api.reserve 'project_delete', self, {'ids' => [id]}
    end

    # Todoist では TAG を所持できないが、Org では所持できるので仮想的に持つ
    def tags
      @raw['tags']
    end

    def todoist_safe_key
      @todoist_safe_key ||= %w(id name color collapsed
                               item_order indent)
    end
  end
end

#{"user_id"=>18,
# "name"=>"sandbox",
# "color"=>7,
# "is_deleted"=>0,
# "collapsed"=>0,
# "id"=>154673446,
# "archived_date"=>nil,
# "item_order"=>3,
# "indent"=>2,
# "archived_timestamp"=>0,
# "shared"=>false,
# "is_archived"=>0},

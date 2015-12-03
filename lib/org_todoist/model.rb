# coding: utf-8
module OrgTodoist
  class Model
    class RecordStore < Hash
      def to_a
        self.map do |key, value|
          value
        end.sort_by{ |v| v.item_order }
      end

      def last_item_order
        size > 0 ? to_a.last.item_order : 0
      end
    end

    class << self
      def top
        self.new 'indent' => 0
      end

      def attribute name
        define_method(name) do
          self.raw[name.to_s]
        end
      end

      def records
        @records ||= RecordStore.new
      end

      def find_or_init attrs
        id = attrs['id']
        if id && records[id]
          records[id].assign(attrs)
          records[id]
        else
          # Todoist に存在しない => 新規作成
          self.new attrs.select{ |k,v| k != 'id' }
        end
      end
    end

    attr_reader   :children, :raw, :temp_id

    def initialize raw_obj
      @old_raw  = raw_obj.clone
      @raw      = raw_obj
      @temp_id  = OrgTodoist.uuid unless persisted?
      store_to_records
    end

    def assign attrs
      @raw = @raw.merge(attrs)
    end

    def save! api
      unless persisted?
        create! api
      else
        if changed?
          update! api
        end
      end
      @old_raw = @raw.clone
    end

    def persisted?
      !!id
    end

    def changed?
      result = !changes.empty?
      if OrgTodoist.verbose? && result
        puts "Model#changed? - changes: #{changes}"
      end
      result
    end

    def changes
      @old_raw.reject do |k, v|
        case k
        when 'due_date_utc'
          v.nil? ||
          v == @raw[k] ||
          DateTime.parse(v) == DateTime.parse(@raw[k])
        else
          v == @raw[k]
        end
      end.map do |k, v|
        [k, [v, @raw[k]]]
      end
    end

    def swap_temp_id id
      @temp_id   = nil
      @raw['id'] = id
      store_to_records
    end

    def to_h
      raw
    end

    def to_args
      raw.select do |k,v|
        todoist_safe_key.include?(k)
      end
    end

    def level
      raw['indent']
    end

    def parse_tree raw_objs
      return [] unless raw_objs
      raw_objs = raw_objs.sort_by{|j| j['item_order'] }

      while raw_objs[0]
        child  = self.class.new raw_objs.shift
        grands = []
        while raw_objs[0] && child.level < raw_objs[0]['indent']
          grands << raw_objs.shift
        end
        child.parse_tree grands
        @children << child
      end

      @children
    end

    private
    def store_to_records
      # top レベルは保存しない
      if id && level && level > 0
        self.class.records[id] = self
      end
    end
  end
end

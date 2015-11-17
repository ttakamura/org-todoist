# coding: utf-8
require 'yaml/store'

module OrgTodoist
  class DB
    def initialize path
      @db = YAML::Store.new(path)
      @in_transaction = false
    end

    def transaction &block
      if @in_transaction
        block.call self
      else
        @db.transaction do
          @in_transaction = true
          block.call self
        end
      end
    ensure
      @in_transaction = false
    end

    def [] key
      transaction{ @db[key] }
    end

    def []= key, value
      transaction{ @db[key] = value }
    end
  end
end

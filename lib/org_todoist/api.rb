# coding: utf-8
module OrgTodoist
  class Api
    include HTTParty
    # debug_output $stdout
    base_uri 'https://todoist.com/API/v6'
    attr_reader :handler, :commands

    def initialize options={}
      @token      = options[:token]   || OrgTodoist.token
      @verbose    = options[:verbose] || false
      @handler    = Handler.new
      @commands   = []
      @new_models = []
    end

    def pull handler=@handler, options={}
      query = options.merge(handler.to_h).merge({resource_types: '["all"]'})
      res   = get '/sync', query: query
      puts "Pull todoist => org" if @verbose
      @handler = Handler.new res
      res
    end

    def reserve type, model, args
      command = {'type'=>type, 'args'=>args, 'uuid'=>OrgTodoist.uuid}
      command['temp_id'] = model.temp_id if model.temp_id
      @commands   << command
      @new_models << model   unless model.persisted?
    end

    def push options={}, &block
      puts "Push org => todoist" if @verbose
      pp @commands if @verbose
      body = {commands: @commands.to_json}
      res  = post '/sync', body: body
      swap_temp_ids res
      @handler    = Handler.new res
      @commands   = []
      @new_models = []
      res
    end

    # 全ての projects と items を削除する
    def seppuku!
      pull
      OrgTodoist::Project.records.each do |k, project|
        if project.name != 'Inbox'
          project.destroy! self
        end
      end
      push

      pull
      OrgTodoist::Item.records.each do |k, item|
        item.destroy! self
      end
      push
    end

    private
    def get path, options
      options[:query][:token] = @token
      Response.new self.class.get(path, options)
    end

    def post path, options
      options[:body][:token] = @token
      Response.new self.class.post(path, options)
    end

    def swap_temp_ids res
      @new_models.each do |model|
        id = res.body['TempIdMapping'][model.temp_id]
        model.swap_temp_id id
      end
    end

    class Handler
      def initialize res=nil
        @seq_no        = res ? res.body['seq_no']        : 0
        @seq_no_global = res ? res.body['seq_no_global'] : 0
      end

      def to_h
        {seq_no: @seq_no, seq_no_global: @seq_no_global}
      end
    end

    class Response
      attr_reader :body, :projects

      def initialize raw_res
        check_error raw_res
        @body = JSON.parse(raw_res.body)

        if @body['Projects']
          items = {}
          @body['Items'].each do |item|
            (items[item['project_id']] ||= []) << item
          end

          @body['Projects'].each do |proj|
            proj['items'] = items[proj['id']] || []
          end

          @projects = Project.top.parse_tree(@body['Projects'])
        end
      end

      private
      def check_error raw_res
        if raw_res.code > 500
          raise "ServerSide error - #{raw_res.code} #{raw_res}"
        elsif raw_res.code > 400
          raise "ClientSide error - #{raw_res.code} #{raw_res}"
        end

        if raw_res && raw_res['SyncStatus']
          raw_res['SyncStatus'].each do |key, value|
            if value == 'ok'
              # {uuid => 'ok'}
            elsif value.is_a?(Hash) && value.values.all?{ |x| x == 'ok' }
              # {uuid => {id => 'ok'}}
            else
              raise "SyncStatus is error - #{raw_res['SyncStatus']}"
            end
          end
        end
      end
    end
  end
end

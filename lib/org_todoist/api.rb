# coding: utf-8
module OrgTodoist
  class Api
    include Logging
    include HTTParty
    # debug_output $stdout
    base_uri 'https://todoist.com/API/v7'
    attr_reader :handler, :commands

    def initialize options={}
      @token      = options[:token]   || OrgTodoist.token
      @handler    = Handler.new
      @commands   = []
      @new_models = []
    end

    def pull handler=@handler, options={}
      query = options.merge(handler.to_h).merge({resource_types: '["all"]'})
      res   = get '/sync', query: query
      res.parse_synced_project
      log.info "Pull todoist => org"
      @handler = Handler.new res
      res
    end

    def reserve type, model, args
      command = {'type'=>type, 'args'=>args, 'uuid'=>OrgTodoist.uuid}
      command['temp_id'] = model.temp_id if model.temp_id
      @commands   << command
      @new_models << model   unless model.persisted?
    end

    def push options={}
      @commands.each_slice(50) do |commands|
        log.info "-" * 40
        log.info "Push org => todoist with #{commands.size} commands"
        log.info "Current handler is #{@handler.to_h}"
        push_chunk_of_commands commands
      end
      @commands   = []
      @new_models = []
      nil
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

    def get_all_completed_items options={}
      query = options
      res   = get '/get_all_completed_items', query: query
      res
    end

    private
    def push_chunk_of_commands commands, options={}
      log.info commands
      body = {commands: commands.to_json}
      res  = post '/sync', body: body
      swap_temp_ids res
      @handler = Handler.new res
    end

    def get path, options
      options[:query][:token] = @token
      Response.new self.class.get(path, options)
    rescue => e
      raise "#{e.message} - GET #{path} #{options}"
    end

    def post path, options
      options[:body][:token] = @token
      Response.new self.class.post(path, options)
    rescue => e
      raise "#{e.message} - POST #{path} #{options}"
    end

    def swap_temp_ids res
      @new_models.each do |model|
        # debug
        log.info "swap_temp_ids() for #{model.inspect}"
        log.info res.body['TempIdMapping']
        # p res.body
        # p model.temp_id
        if id = res.body['TempIdMapping'][model.temp_id]
          model.swap_temp_id id
        else
          log.info "Missing TempIdMapping for #{model.inspect}"
        end
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
      include Logging
      attr_reader :body, :projects

      def initialize raw_res
        @body = JSON.parse(raw_res.body)
        check_error raw_res
      end

      def parse_synced_project
        if @body['projects']
          @body['labels'].each do |label|
            Label.new(label)
          end

          notes = {}
          @body['notes'].each do |note|
            (notes[note['item_id']] ||= []) << note
          end

          items = {}
          @body['items'].each do |item|
            item['notes'] = notes[item['id']] || []
            (items[item['project_id']] ||= []) << item
          end

          @body['projects'].each do |proj|
            proj['items'] = items[proj['id']] || []
          end

          @projects = Project.top.parse_tree(@body['projects'])
        end
      end

      private
      def check_error raw_res
        if raw_res.code > 500
          raise "ServerSide error - #{raw_res.code} #{raw_res}"
        elsif raw_res.code > 400
          raise "ClientSide error - #{raw_res.code} #{raw_res}"
        end

        # p @body
        if @body['SyncStatus']
          @body['SyncStatus'].each do |key, value|
            if value == 'ok'
              # {uuid => 'ok'}
              log.info "SyncStatus is OK key:#{key}, value:#{value}"
            elsif value.is_a?(Hash) && value.values.all?{ |x| x == 'ok' }
              # {uuid => {id => 'ok'}}
            else
              log.error "SyncStatus is error key:#{key}, value:#{value} - #{raw_res['SyncStatus']}"
            end
          end
        end
      end
    end
  end
end

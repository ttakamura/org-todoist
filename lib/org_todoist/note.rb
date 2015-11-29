# coding: utf-8
module OrgTodoist
  class Note < Model
    attribute :id
    attribute :content
    attribute :item_id

    def initialize raw_item={}
      @item = raw_item.delete('item')
      super(raw_item)
    end

    def item
      @item || @raw['item']
    end

    def content= new_text
      @raw['content'] = new_text
    end

    def create! api
      @raw['item_id'] = item.id
      api.reserve 'note_add', self, to_args
    end

    def update! api
      api.reserve 'note_update', self, to_args
    end

    def destroy! api
      raise 'Not persisted' unless persisted?
      api.reserve 'note_delete', self, {'id' => id, 'item_id' => item_id}
    end

    def todoist_safe_key
      @todoist_safe_key ||= %w(id content item_id)
    end
  end
end

# {
#  "id": 17299568,
#  "posted_uid": 1855589,
#  "project_id": 128501470,
#  "item_id": 33548400,
#  "content": "Note",
#  "file_attachment": {
#    "file_type": "text/plain",
#    "file_name": "File1.txt",
#    "file_size": 1234,
#    "file_url": "https://example.com/File1.txt",
#    "upload_state": "completed"
#  },
#  "uids_to_notify": null,
#  "is_deleted": 0,
#  "is_archived": 0,
#  "posted": "Wed 01 Oct 2014 14:54:55 +0000"
# }

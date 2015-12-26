# coding: utf-8
module OrgTodoist
  class Label < Model
    attribute :id
    attribute :name
    attribute :color
    attribute :item_order

    def self.[] name
      records.values.find{ |l| l.name == name }
    end

    def self.tags_to_labels tags
      tags.map do |tag|
        if label = Label[tag]
          label.id
        else
          nil
        end
      end.compact.sort.uniq
    end

    def initialize raw_label={}
      super(raw_label)
    end

    def create! api
      api.reserve 'label_add', self, to_args
    end

    def update! api
      api.reserve 'label_update', self, to_args
    end

    def destroy! api
      raise 'Not persisted' unless persisted?
      api.reserve 'label_delete', self, {'id' => id}
    end

    def todoist_safe_key
      @todoist_safe_key ||= %w(id name)
    end

    private
    def can_store_to_records?
      id
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

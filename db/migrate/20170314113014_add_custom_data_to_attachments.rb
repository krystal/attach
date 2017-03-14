class AddCustomDataToAttachments < ActiveRecord::Migration

  def up
    add_column :attachments, :custom, :text
  end

  def down
    remove_column :attachments, :custom
  end

end

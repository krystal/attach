class AddIndexToAttachmentBinaries < ActiveRecord::Migration

  def up
    add_index :attachment_binaries, :attachment_id
  end

  def down
    remove_index :attachment_binaries, :attachment_id
  end

end

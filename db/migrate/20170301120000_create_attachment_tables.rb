class CreateAttachmentTables < ActiveRecord::Migration
  def up
    create_table :attachments do |t|
      t.integer :owner_id
      t.string  :owner_type, :token, :digest, :role, :type, :file_name, :file_type, :cache_type, :cache_max_age, :disposition
      t.integer :file_size
      t.integer :parent_id
      t.boolean :processed, :default => false
      t.timestamps
      t.index :owner_id
    end

    create_table :attachment_binaries do |t|
      t.integer :attachment_id
      t.binary :data, :limit => 10.megabytes
      t.timestamps
    end
  end

  def down
    drop_table :attachments
    drop_table :attachment_binaries
  end
end

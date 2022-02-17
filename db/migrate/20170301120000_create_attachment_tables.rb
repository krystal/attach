# frozen_string_literal: true

class CreateAttachmentTables < ActiveRecord::Migration[6.0]

  def up
    create_table :attachments do |t|
      t.belongs_to :owner, polymorphic: true
      t.string :token, :digest, :role, :type, :file_name, :file_type, :cache_type, :cache_max_age, :disposition
      t.bigint :file_size
      t.belongs_to :parent
      t.boolean :processed, default: false
      t.text :custom
      t.boolean :serve, default: false
      t.timestamps
      t.index :token, length: 16
    end

    create_table :attachment_binaries do |t|
      t.belongs_to :attachment
      t.binary :data, limit: 10.megabytes
      t.timestamps
    end
  end

  def down
    drop_table :attachments
    drop_table :attachment_binaries
  end

end

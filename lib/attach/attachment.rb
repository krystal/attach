require 'securerandom'
require 'digest/sha1'
require 'attach/attachment_binary'

module Attach
  class Attachment < ActiveRecord::Base

    # Set the table name
    self.table_name = 'attachments'
    self.inheritance_column = 'sti_type'

    # This will be the ActionDispatch::UploadedFile object which be diseminated
    # by the class on save.
    attr_accessor :uploaded_file
    attr_writer :binary

    # Relationships
    belongs_to :owner, :polymorphic => true
    belongs_to :parent, :class_name => 'Attach::Attachment', :optional => true
    has_many :children, :class_name => 'Attach::Attachment', :dependent => :destroy, :foreign_key => :parent_id

    # Validations
    validates :file_name, :presence => true
    validates :file_type, :presence => true
    validates :file_size, :presence => true
    validates :digest, :presence => true
    validates :token, :presence => true, :uniqueness => true

    # All attachments should have a token assigned to this
    before_validation { self.token = SecureRandom.uuid if self.token.blank? }

    # Copy values from the `uploaded_file` and set them as the appropriate
    # fields on this model
    before_validation do
      if self.uploaded_file
        self.binary = self.uploaded_file.tempfile.read
        self.file_name = self.uploaded_file.original_filename
        self.file_type = self.uploaded_file.content_type
      end

      self.digest = Digest::SHA1.hexdigest(self.binary)
      self.file_size = self.binary.bytesize
    end

    # Write the binary to the backend storage
    after_create do
      Attach.backend.write(self, self.binary)
    end

    # Remove any old images for this owner/role when this is added
    after_create do
      self.owner.attachments.where.not(:id => self).where(:parent_id => self.parent_id, :role => self.role).destroy_all
    end

    # Run any post-upload processing after the record has been committed
    after_commit do
      unless self.processed? || self.parent_id
        self.processor.queue_or_process
      end
    end

    # Remove the file from the backends
    after_destroy do
      Attach.backend.delete(self)
    end

    # Return the attachment for a given role
    def self.for(role)
      self.where(:role => role).first
    end

    # Return the binary data for this attachment
    def binary
      @binary ||= persisted? ? Attach.backend.read(self) : nil
    end

    # Return the path to the attachment
    def url
      Attach.backend.url(self)
    end

    # Is the attachment an image?
    def image?
      file_type =~ /\Aimage\//
    end

    # Return a processor for this attachment
    def processor
      @processor ||= Processor.new(self)
    end

    # Return a child process
    def child(role)
      @cached_children ||= {}
      @cached_children[role.to_sym] ||= self.children.where(:role => role).first || :nil
      @cached_children[role.to_sym] == :nil ? nil : @cached_children[role.to_sym]
    end

    # Try to return a given otherwise revert to the parent
    def try(role)
      child(role) || self
    end

    # Add a child attachment
    def add_child(role, &block)
      attachment = self.children.build
      attachment.role = role
      attachment.owner = self.owner
      attachment.file_name = self.file_name
      attachment.file_type = self.file_type
      attachment.disposition = self.disposition
      attachment.cache_type = self.cache_type
      attachment.cache_max_age = self.cache_max_age
      attachment.type = self.type
      block.call(attachment)
      attachment.save!
    end

  end
end

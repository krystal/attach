# frozen_string_literal: true

require 'securerandom'
require 'digest/sha1'
require 'attach/attachment_binary'
require 'attach/processor'
require 'attach/blob_types/raw'
require 'attach/blob_types/file'

module Attach
  class Attachment < ActiveRecord::Base

    self.table_name = 'attachments'
    self.inheritance_column = 'sti_type'

    attr_writer :backend

    belongs_to :owner, polymorphic: true
    belongs_to :parent, class_name: 'Attach::Attachment', optional: true
    has_many :children, class_name: 'Attach::Attachment', dependent: :destroy, foreign_key: :parent_id

    validates :file_name, presence: true
    validates :file_type, presence: true
    validates :file_size, presence: true
    validates :digest, presence: true
    validates :token, presence: true, uniqueness: { case_sensitive: false }

    serialize :custom, Hash

    before_validation :set_token
    before_validation :set_digest
    before_validation :set_file_size

    after_create :write_blob_to_backend
    after_create :destroy_other_attachments_for_same_parent

    after_commit :queue_or_process_with_processor

    after_destroy :remove_from_backend

    def blob
      return @blob if instance_variable_defined?('@blob')
      return nil unless persisted?

      @blob = backend.read(self)
    end

    def blob=(blob)
      unless blob.nil? || blob.is_a?(BlobTypes::File) || blob.is_a?(BlobTypes::Raw)
        raise ArgumentError, 'Only nil or a File/Raw blob type can be set as a blob for an attachment'
      end

      @blob = blob
    end

    def url
      backend.url(self)
    end

    def image?
      file_type =~ /\Aimage\//
    end

    def processor
      @processor ||= Processor.new(self)
    end

    def child(role)
      @cached_children ||= {}
      @cached_children[role.to_sym] ||= children.where(role: role).first || :nil
      @cached_children[role.to_sym] == :nil ? nil : @cached_children[role.to_sym]
    end

    def try(role)
      child(role) || self
    end

    def add_child(role, &block)
      attachment = children.build(attributes.slice(:owner, :file_name, :file_type, :disposition, :cache_type,
                                                   :cache_max_age, :type))
      attachment.role = role
      block.call(attachment)
      attachment.save!
    end

    # rubocop:disable Metrics/AbcSize
    def copy_attributes_from_file(file)
      case file.class.name
      when 'ActionDispatch::Http::UploadedFile'
        self.blob = BlobTypes::File.new(file.tempfile)
        self.file_name = file.original_filename
        self.file_type = file.content_type
      when 'Attach::File'
        self.binary = BlobTypes::Raw.new(file.data)
        self.file_name = file.name
        self.file_type = file.type
      else
        self.blob = BlobTypes::Raw.new(file)
        self.file_name = 'untitled'
        self.file_type = 'application/octet-stream'
      end
    end
    # rubocop:enable Metrics/AbcSize

    private

    def backend
      @backend || Attach.backend
    end

    def write_blob_to_backend
      return if blob.blank?

      backend.write(self, blob)
    end

    def destroy_other_attachments_for_same_parent
      owner.attachments.where.not(id: self).where(parent_id: parent_id, role: role).destroy_all
    end

    def set_token
      return if token.present?

      self.token = SecureRandom.uuid
    end

    def set_digest
      return if digest.present?
      return if blob.blank?

      self.digest = blob.digest
    end

    def set_file_size
      return if file_size.present?
      return if blob.blank?

      self.file_size = blob.size
    end

    def remove_from_backend
      backend.delete(self)
    end

    def queue_or_process_with_processor
      return if processed?
      return if parent_id

      processor.queue_or_process
    end

    class << self

      def for(role)
        where(role: role).first
      end

    end

  end
end

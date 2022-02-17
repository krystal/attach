# frozen_string_literal: true

require 'attach/attachment_binary'
require 'attach/backends/abstract'
require 'attach/blob_types/raw'

module Attach
  module Backends
    class Database < Abstract

      def read(attachment)
        binary = AttachmentBinary.find_by(attachment_id: attachment.id)
        return if binary.nil?

        BlobTypes::Raw.new(binary.data)
      end

      def write(attachment, blob)
        binary_object = AttachmentBinary.where(attachment_id: attachment.id).first_or_initialize
        binary_object.data = blob.read
        binary_object.save!
        binary_object
      end

      def delete(attachment)
        AttachmentBinary.where(attachment_id: attachment.id).destroy_all
      end

    end
  end
end

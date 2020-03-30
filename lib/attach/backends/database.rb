require 'attach/backends/abstract'

module Attach
  module Backends
    class Database < Abstract

      def read(attachment)
        if binary = AttachmentBinary.find_by_attachment_id(attachment.id)
          binary.data
        else
          nil
        end
      end

      def write(attachment, binary)
        binary_object = AttachmentBinary.where(:attachment_id => attachment.id).first_or_initialize
        if binary.respond_to?(:path)
          binary.rewind
          binary_object.data = binary.read
        else
          binary_object.data = binary
        end
        binary_object.save!
        binary_object
      end

      def delete(attachment)
        AttachmentBinary.where(:attachment_id => attachment.id).destroy_all
      end

      def read_multi(attachments)
        AttachmentBinary.where(:attachment_id => attachments.map(&:id)).each_with_object({}) do |binary, hash|
          hash[binary.attachment_id] = binary.data
        end
      end

    end
  end
end

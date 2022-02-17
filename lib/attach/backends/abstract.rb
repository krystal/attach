# frozen_string_literal: true

module Attach
  module Backends
    class Abstract

      def initialize(config = {})
        @config = config
      end

      #
      #  Return the data for the given attachment
      #
      def read(attachment)
      end

      #
      #  Write data for the given attachment
      #
      def write(attachment, data)
      end

      #
      #  Delete the data for the given attachment
      #
      def delete(attachment)
      end

      #
      # Return the URL that this attachment can be accessed at
      #
      def url(attachment)
        "#{Attach.asset_host}/attachment/#{attachment.token}/#{attachment.file_name}"
      end

      #
      #  Return binaries for a set of files. They should be returned as a hash consisting
      # of the attachment ID followed by the data
      #
      def read_multi(attachments)
        attachments.compact.each_with_object({}) do |attachment, hash|
          hash[attachment] = read(attachment)
        end
      end

      #
      # Return the SHA1 digest of a given binary
      #
      def digest(binary)
        if binary.respond_to?(:path)
          sha1 = Digest::SHA1.new
          binary.binmode
          binary.rewind
          while chunk = binary.read(1024 * 1024)
            sha1.update(chunk)
          end
          sha1.hexdigest
        else
          Digest::SHA1.hexdigest(binary)
        end
      end

      #
      # Return the bytesize of a given binary
      #
      def bytesize(binary)
        if binary.respond_to?(:path)
          ::File.size(binary.path)
        else
          binary.bytesize
        end
      end

    end
  end
end

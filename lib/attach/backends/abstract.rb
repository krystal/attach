module Attach
  module Backends
    class Abstract

      def initialize(config = {})
        @config = config
      end

      #
      # Return the data for the given attachment
      #
      def read(attachment)
      end

      #
      # Write data for the given attachment
      #
      def write(attachment, data)
      end

      #
      # Delete the data for the given attachment
      #
      def delete(attachment)
      end

      #
      # Return the URL that this attachment can be accessed at
      #
      def url(attachment)
        "/attachment/#{attachment.token}/#{attachment.file_name}"
      end

      #
      # Return binaries for a set of files. They should be returned as a hash consisting
      # of the attachment ID followed by the data
      #
      def read_multi(attachments)
        attachments.compact.each_with_object({}) do |attachment, hash|
          hash[attachment] = read(attachment)
        end
      end

    end
  end
end

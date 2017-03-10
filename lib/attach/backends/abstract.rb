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

    end
  end
end

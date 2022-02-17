# frozen_string_literal: true

module Attach
  module BlobTypes
    class Raw

      def initialize(data)
        @data = data
      end

      def read
        @data
      end

      def size
        @data.bytesize
      end

      def digest
        Digest::SHA1.hexdigest(@data)
      end

    end
  end
end

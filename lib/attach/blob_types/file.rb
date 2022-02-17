# frozen_string_literal: true

module Attach
  module BlobTypes
    class File

      attr_reader :file

      def initialize(file)
        @file = file
      end

      def read
        @file.rewind
        @file.read
      end

      def size
        @file.size
      end

      def digest
        Digest::SHA1.file(@file.path).to_s
      end

    end
  end
end

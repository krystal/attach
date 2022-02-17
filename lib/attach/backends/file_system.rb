# frozen_string_literal: true

require 'fileutils'
require 'attach/backends/abstract'

module Attach
  module Backends
    class FileSystem < Abstract

      def read(attachment)
        file = File.new(path_for_attachment(attachment))
        BlobTypes::File.new(file)
      end

      def write(attachment, blob)
        path = path_for_attachment(attachment)
        FileUtils.mkdir_p(::File.dirname(path))

        if blob.is_a?(BlobTypes::File)
          FileUtils.mv(blob.file.path, path)
          return path
        end

        ::File.binwrite(path, blob.read)

        path
      end

      def delete(attachment)
        path = path_for_attachment(attachment)
        FileUtils.rm(path) if ::File.file?(path)
        path
      end

      private

      def root_dir
        @config[:root] ||= Rails.root.join('attachments')
      end

      def path_for_attachment(attachment)
        ::File.join(root_dir, attachment.token[0, 2], attachment.token[2, 2], attachment.token[4, 40])
      end

    end
  end
end

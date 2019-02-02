require 'fileutils'
require 'attach/backends/abstract'

module Attach
  module Backends
    class FileSystem < Abstract

      def read(attachment)
        ::File.read(path_for_attachment(attachment))
      end

      def write(attachment, data)
        path = path_for_attachment(attachment)
        FileUtils.mkdir_p(::File.dirname(path))
        if data.respond_to?(:path)
          FileUtils.mv(data.path, path)
        else
          ::File.open(path, 'wb') do |f|
            f.write(data)
          end
        end
      end

      def delete(attachment)
        path = path_for_attachment(attachment)
        FileUtils.rm(path) if ::File.file?(path)
      end

      private

      def root_dir
        @config[:root] ||= Rails.root.join('attachments')
      end

      def path_for_attachment(attachment)
        ::File.join(root_dir, attachment.token[0,2], attachment.token[2,2], attachment.token[4,40])
      end

    end
  end
end

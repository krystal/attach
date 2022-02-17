# frozen_string_literal: true

require 'attach/railtie' if defined?(Rails)

module Attach

  class << self

    attr_writer :backend
    attr_accessor :asset_host

    def backend
      @backend ||= begin
        require 'attach/backends/database'
        Attach::Backends::Database.new
      end
    end

    def use_filesystem!(config = {})
      require 'attach/backends/file_system'
      @backend = Attach::Backends::FileSystem.new(config)
    end

  end

end

require 'records_manipulator'
require 'attach/processor'
require 'attach/file'
require 'attach/railtie' if defined?(Rails)

module Attach

  def self.backend
    @backend ||= begin
      require 'attach/backends/database'
      Attach::Backends::Database.new
    end
  end

  def self.backend=(backend)
    @backend = backend
  end

  def self.asset_host
    @asset_host
  end

  def self.asset_host=(host)
    @asset_host = host
  end

  def self.use_filesystem!(config = {})
    require 'attach/backends/file_system'
    @backend = Attach::Backends::FileSystem.new(config)
  end

end

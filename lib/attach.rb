require 'records_manipulator'
require 'attach/processor'
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

  def self.use_filesystem!(config = {})
    require 'attach/backends/file_system'
    @backend = Attach::Backends::FileSystem.new(config)
  end

end

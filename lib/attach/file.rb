module Attach
  class File

    attr_accessor :data
    attr_accessor :name
    attr_accessor :type

    def initialize(data, name = "untitled", type = "application/octet-stream")
      @data = data
      @name = name
      @type = type
    end

  end
end

module Attach
  class File

    attr_accessor :data
    attr_accessor :file_name
    attr_accessor :file_type

    def initialize(data, file_name = "untitled", file_type = "application/octet-stream")
      @data = data
      @file_name = file_name
      @file_type = file_type
    end

  end
end

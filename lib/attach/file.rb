# frozen_string_literal: true

module Attach
  class File

    attr_accessor :data, :name, :type

    def initialize(data, name = 'untitled', type = 'application/octet-stream')
      @data = data
      @name = name
      @type = type
    end

  end
end

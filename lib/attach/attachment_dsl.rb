# frozen_string_literal: true

module Attach
  class AttachmentDSL

    attr_reader :processors, :validators

    def initialize(&block)
      @processors = []
      @validators = []
      instance_eval(&block) if block_given?
    end

    def processor(*processors, &block)
      processors.each { |p| @processors << p }
      @processors << block if block_given?
    end

    def validator(*validators, &block)
      validators.each { |v| @validators << v }
      @validators << block if block_given?
    end

  end
end

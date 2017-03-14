module Attach
  class AttachmentDSL

    attr_reader :processors
    attr_reader :validators

    def initialize(&block)
      @processors = []
      @validators = []
      if block_given?
        instance_eval(&block)
      end
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

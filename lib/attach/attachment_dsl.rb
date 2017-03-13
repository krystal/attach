module Attach
  class AttachmentDSL

    def initialize(&block)
      if block_given?
        instance_eval(&block)
      end
    end

    def processor?
      !@processor.nil?
    end

    def processor(&block)
      block_given? ? @processor = block : @processor
    end

    def validator?
      !@validator.nil?
    end

    def validator(&block)
      block_given? ? @validator = block : @validator
    end

  end
end

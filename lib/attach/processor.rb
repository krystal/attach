module Attach
  class Processor

    def self.background(&block)
      @background_block = block
    end

    def self.background_block
      @background_block
    end

    def self.register(model, attribute, &block)
      @processors ||= {}
      @processors[[model.to_s, attribute.to_s]] ||= []
      @processors[[model.to_s, attribute.to_s]] = block
    end

    def self.processor(model, attribute)
      @processors && @processors[[model.to_s, attribute.to_s]]
    end

    def initialize(attachment)
      @attachment = attachment
    end

    def process
      call_processors(@attachment)
      @attachment.processed = true
      @attachment.save(:validate => false)
    end

    def queue_or_process
      if self.class.background_block
        self.class.background_block.call(@attachment)
      else
        process
      end
    end

    private

    def call_processors(attachment)
      if p = self.class.processor(attachment.owner_type, attachment.role)
        p.call(attachment)
      end
    end

  end
end

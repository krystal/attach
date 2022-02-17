# frozen_string_literal: true

module Attach
  class Processor

    class << self

      attr_reader :background_block

      def background(&block)
        @background_block = block
      end

    end
    def initialize(attachment)
      @attachment = attachment
    end

    def process
      call_processors
      mark_as_processed
    end

    def queue_or_process
      return self.class.background_block.call(@attachment) if self.class.background_block

      process
    end

    private

    def call_processors
      return if @attachment.role.blank?
      return if @attachment.owner.nil?

      processors = @attachment.owner.class.attachment_processors[@attachment.role.to_sym]
      return if processors.nil? || processors.empty?

      processors.each do |processor|
        processor.call(@attachment)
      end
    end

    def mark_as_processed
      @attachment.processed = true
      @attachment.save!
    end

  end
end

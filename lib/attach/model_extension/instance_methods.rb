# frozen_string_literal: true

require 'attach/attachment'

module Attach
  module ModelExtension
    module InstanceMethods

      def process_pending_attachments
        attachments.where(role: @pending_attachment_deletions).destroy_all if @pending_attachment_deletions

        return if @pending_attachments.nil? || @pending_attachments.empty?

        @pending_attachments.each_value(&:save!)
        @pending_attachments = nil
      end

      private

      def get_attachment(name)
        iv_name = "@#{name}"
        return instance_variable_get(iv_name) if instance_variable_defined?(iv_name)

        if attachment = attachments.where(role: name, parent_id: nil).first
          return instance_variable_set(iv_name, attachment)
        end

        instance_variable_set(iv_name, nil)
      end

      def set_attachment(name, file, **options)
        attachment = Attachment.new({ owner: self, role: name }.merge(options))
        attachment.copy_attributes_from_file(file)
        @pending_attachments ||= {}
        @pending_attachments[name] = attachment
        instance_variable_set("@#{name}", attachment)
      end

      def validate_attachments
        return if @pending_attachments.nil? || @pending_attachments.empty?

        @pending_attachments.each_value do |attachment|
          validators = self.class.attachment_validators[attachment.role.to_sym]
          next if validators.blank?

          validators.each do |validator|
            validator.call(attachment, errors)
          end
        end
      end

    end
  end
end

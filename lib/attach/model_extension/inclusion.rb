# frozen_string_literal: true

module Attach
  module ModelExtension
    class Inclusion

      def initialize(scope, *options)
        @scope = scope
        @options = options
        @fields = {}
      end

      def prepare
        return if @scope.empty?

        prepare_fields
        find_all_attachments
        find_child_attachments
        add_attachments_to_records
      end

      private

      def prepare_fields
        @options.each do |field|
          case field
          when Symbol
            @fields[field] = []
          when Hash
            field.each do |k, v|
              case v
              when Array
                @fields.merge!(field)
              when Symbol
                @fields[k] = [v]
              end
            end
          end
        end
      end

      def find_all_attachments
        @attachment_ids = []
        @attachments_map = Attachment.where(
          owner_id: @scope.map(&:id),
          owner_type: @scope.first.class.name,
          role: @fields.keys
        ).each_with_object({}) do |attachment, hash|
          hash[attachment.owner_id] ||= {}
          hash[attachment.owner_id][attachment.role] = attachment
          @attachment_ids << attachment.id
        end
      end

      def find_child_attachments
        @child_attachments = Attachment.where(
          parent: @attachment_ids,
          role: @fields.values.flatten.compact
        ).each_with_object({}) do |attachment, hash|
          hash[attachment.parent_id] ||= {}
          hash[attachment.parent_id][attachment.role] = attachment
        end
      end

      def add_attachments_to_records
        @scope.each do |record|
          preloaded_attachments = @attachments_map[record.id] || {}
          @fields.each_key do |role|
            cache_attachment(
              record,
              role,
              preloaded_attachments[role.to_s]
            )
          end
        end
      end

      def cache_attachment(record, role, attachment)
        record.instance_variable_set("@#{role}", attachment)
        return if attachment.nil?

        @fields[role.to_sym].each do |child_role|
          child_attachment = @child_attachments.dig(attachment.id, child_role.to_s)
          if attachment.instance_variable_get('@cached_children').nil?
            attachment.instance_variable_set('@cached_children', {})
          end
          attachment.instance_variable_get('@cached_children')[child_role] = child_attachment
        end
      end

    end
  end
end

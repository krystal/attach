# frozen_string_literal: true

require 'attach/attachment_dsl'
require 'attach/attachment'
require 'attach/model_extension/inclusion'

require 'records_manipulator/relation_extension'
ActiveRecord::Relation.include RecordsManipulator::RelationExtension

require 'records_manipulator/base_extension'
ActiveRecord::Base.include RecordsManipulator::BaseExtension

module Attach
  module ModelExtension
    module ClassMethods

      def attachment_validators
        @attachment_validators ||= {}
      end

      def attachment_processors
        @attachment_processors ||= {}
      end

      def attachment(name, **options, &block)
        setup_model
        parse_dsl(name, &block)

        define_method name do
          get_attachment(name)
        end

        define_method "#{name}=" do |file|
          set_attachment(name, file, **options)
        end

        define_method "#{name}_delete" do
          instance_variable_get("@#{name}_delete")
        end

        define_method "#{name}_delete=" do |delete|
          delete = delete.to_i
          instance_variable_set("@#{name}_delete", delete)
          if delete == 1
            @pending_attachment_deletions ||= []
            @pending_attachment_deletions << name
          end
        end
      end

      def includes_attachment(*args, **options)
        manipulate do |scope|
          inclusion = Inclusion.new(scope, *args, **options)
          inclusion.prepare
        end
      end

      private

      def setup_model
        return if reflect_on_all_associations(:has_many).map(&:name).include?(:attachments)

        has_many :attachments, as: :owner, dependent: :destroy, class_name: 'Attach::Attachment'
        validate :validate_attachments
        after_save :process_pending_attachments
      end

      def parse_dsl(name, &block)
        dsl = AttachmentDSL.new(&block)
        attachment_validators[name.to_sym] = dsl.validators
        attachment_processors[name.to_sym] = dsl.processors
      end

    end
  end
end
